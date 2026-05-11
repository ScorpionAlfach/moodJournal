const https = require('https');
const { GigaChat } = require('gigachat');
const Mood = require('../models/Mood');

const SUGGESTION_CATEGORIES = new Set([
  'wellness',
  'sleep',
  'activity',
  'social',
  'mindfulness'
]);

const FALLBACK_ICON_BY_CATEGORY = {
  wellness: 'heart.fill',
  sleep: 'moon.fill',
  activity: 'figure.walk',
  social: 'person.2.fill',
  mindfulness: 'brain.head.profile'
};

const AI_ASSISTANT_SYSTEM_PROMPT = `
Ты AI-помощник приложения "Дневник настроения".
Отвечай по-русски, тепло, спокойно и практично.
Помогай пользователю с эмоциональным благополучием, дневником настроения, стрессом, сном, привычками и саморефлексией.
Не ставь медицинские диагнозы и не выдавай себя за врача или психотерапевта.
Если пользователь описывает риск причинения вреда себе или другим, мягко предложи немедленно обратиться за срочной помощью, к близкому человеку или специалисту.
Давай конкретные небольшие шаги, которые можно попробовать сегодня.
`.trim();

class AiProviderError extends Error {
  constructor(message, statusCode = 502, cause) {
    super(message);
    this.name = 'AiProviderError';
    this.statusCode = statusCode;
    this.cause = cause;
    this.publicMessage = statusCode === 503
      ? 'AI-сервис не настроен'
      : 'AI-сервис временно недоступен';
  }
}

let gigachatClient;

const parseBooleanEnv = (value, defaultValue) => {
  if (value === undefined) {
    return defaultValue;
  }

  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
};

const parseNumberEnv = (value, defaultValue) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : defaultValue;
};

const isGigaChatConfigured = () => Boolean(
  process.env.GIGACHAT_CREDENTIALS ||
  process.env.GIGACHAT_ACCESS_TOKEN ||
  (process.env.GIGACHAT_USER && process.env.GIGACHAT_PASSWORD)
);

const setConfigValue = (config, key, value) => {
  if (value !== undefined && value !== '') {
    config[key] = value;
  }
};

const createGigaChatClient = () => {
  if (!isGigaChatConfigured()) {
    throw new AiProviderError('GigaChat credentials are missing', 503);
  }

  const httpsAgent = new https.Agent({
    rejectUnauthorized: parseBooleanEnv(process.env.GIGACHAT_REJECT_UNAUTHORIZED, false)
  });

  const config = {
    httpsAgent,
    model: process.env.GIGACHAT_MODEL || 'GigaChat',
    scope: process.env.GIGACHAT_SCOPE || 'GIGACHAT_API_PERS',
    timeout: parseNumberEnv(process.env.GIGACHAT_TIMEOUT, 30)
  };

  setConfigValue(config, 'credentials', process.env.GIGACHAT_CREDENTIALS);
  setConfigValue(config, 'accessToken', process.env.GIGACHAT_ACCESS_TOKEN);
  setConfigValue(config, 'baseUrl', process.env.GIGACHAT_BASE_URL);
  setConfigValue(config, 'authUrl', process.env.GIGACHAT_AUTH_URL);
  setConfigValue(config, 'user', process.env.GIGACHAT_USER);
  setConfigValue(config, 'password', process.env.GIGACHAT_PASSWORD);

  if (process.env.GIGACHAT_PROFANITY_CHECK !== undefined) {
    config.profanityCheck = parseBooleanEnv(process.env.GIGACHAT_PROFANITY_CHECK, true);
  }

  return new GigaChat(config);
};

const getGigaChatClient = () => {
  if (!gigachatClient) {
    gigachatClient = createGigaChatClient();
  }

  return gigachatClient;
};

const truncate = (value, maxLength = 500) => {
  if (!value) {
    return '';
  }

  const stringValue = String(value).trim();
  return stringValue.length > maxLength
    ? `${stringValue.slice(0, maxLength - 1)}…`
    : stringValue;
};

const getRecentMoods = (userId, limit = 30) => Mood.find({ userId })
  .sort({ date: -1, createdAt: -1 })
  .limit(limit);

const getMoodContext = (recentMoods) => {
  if (recentMoods.length === 0) {
    return 'У пользователя пока нет записей настроения.';
  }

  const avgMood = recentMoods.reduce((sum, mood) => sum + mood.level, 0) / recentMoods.length;
  const factorCounts = recentMoods
    .flatMap((mood) => mood.factors || [])
    .reduce((counts, factor) => {
      counts[factor] = (counts[factor] || 0) + 1;
      return counts;
    }, {});

  const topFactors = Object.entries(factorCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([factor, count]) => `${factor}: ${count}`)
    .join(', ') || 'нет отмеченных факторов';

  const entries = recentMoods.slice(0, 10).map((mood) => {
    const date = mood.date ? mood.date.toISOString().slice(0, 10) : 'без даты';
    const factors = mood.factors?.length ? mood.factors.join(', ') : 'без факторов';
    const note = mood.note ? `, заметка: "${truncate(mood.note, 160)}"` : '';
    return `- ${date}: уровень ${mood.level}/5, факторы: ${factors}${note}`;
  });

  return [
    `Среднее настроение за последние ${recentMoods.length} записей: ${avgMood.toFixed(1)}/5.`,
    `Частые факторы: ${topFactors}.`,
    'Последние записи:',
    ...entries
  ].join('\n');
};

const normalizeConversationMessages = (messages = [], currentMessage) => {
  const normalized = messages
    .filter((message) => ['user', 'assistant'].includes(message.role) && message.content)
    .slice(-12)
    .map((message) => ({
      role: message.role,
      content: truncate(message.content, 2000)
    }));

  const lastMessage = normalized[normalized.length - 1];
  if (!lastMessage || lastMessage.role !== 'user' || lastMessage.content !== currentMessage) {
    normalized.push({
      role: 'user',
      content: truncate(currentMessage, 2000)
    });
  }

  return normalized;
};

const callGigaChat = async (messages, options = {}) => {
  try {
    const response = await getGigaChatClient().chat({
      messages,
      temperature: options.temperature ?? 0.55,
      max_tokens: options.maxTokens ?? 1200
    });

    const content = response.choices?.[0]?.message?.content?.trim();
    if (!content) {
      throw new Error('GigaChat returned an empty response');
    }

    return content;
  } catch (error) {
    if (error instanceof AiProviderError) {
      throw error;
    }

    const status = error.response?.status;
    const providerMessage = typeof error.response?.data === 'string'
      ? error.response.data
      : error.response?.data?.message;

    console.error('GigaChat API error:', {
      status,
      message: providerMessage || error.message
    });

    throw new AiProviderError('GigaChat request failed', status === 401 ? 503 : 502, error);
  }
};

const parseSuggestionsJson = (content) => {
  const withoutMarkdown = content
    .replace(/^```(?:json)?/i, '')
    .replace(/```$/i, '')
    .trim();

  const start = withoutMarkdown.indexOf('[');
  const end = withoutMarkdown.lastIndexOf(']');
  const jsonString = start >= 0 && end > start
    ? withoutMarkdown.slice(start, end + 1)
    : withoutMarkdown;

  const parsed = JSON.parse(jsonString);
  const items = Array.isArray(parsed) ? parsed : parsed.suggestions;

  if (!Array.isArray(items)) {
    throw new Error('Suggestions response is not an array');
  }

  return items
    .slice(0, 5)
    .filter((suggestion) => suggestion && typeof suggestion === 'object')
    .map((suggestion, index) => {
      const category = SUGGESTION_CATEGORIES.has(suggestion.category)
        ? suggestion.category
        : 'wellness';

      return {
        id: truncate(suggestion.id, 60) || `gigachat_${index + 1}`,
        title: truncate(suggestion.title, 80) || 'Рекомендация',
        content: truncate(suggestion.content, 260) || 'Попробуйте небольшой шаг, который поддержит ваше самочувствие сегодня.',
        category,
        icon: truncate(suggestion.icon, 40) || FALLBACK_ICON_BY_CATEGORY[category]
      };
    })
    .filter((suggestion) => suggestion.title && suggestion.content);
};

const getPersonalizedSuggestions = async (userId) => {
  const recentMoods = await getRecentMoods(userId);
  const moodContext = getMoodContext(recentMoods);

  try {
    const content = await callGigaChat([
      {
        role: 'system',
        content: [
          AI_ASSISTANT_SYSTEM_PROMPT,
          'Верни только валидный JSON без markdown.',
          'Формат: массив из 3-5 объектов { "id": string, "title": string, "content": string, "category": string, "icon": string }.',
          'category строго один из: wellness, sleep, activity, social, mindfulness.',
          'icon должен быть именем SF Symbols, например heart.fill, moon.fill, figure.walk, person.2.fill, brain.head.profile, wind.'
        ].join('\n')
      },
      {
        role: 'user',
        content: [
          'Сформируй короткие персональные рекомендации для экрана приложения.',
          'Каждая рекомендация должна быть конкретной, бережной и применимой сегодня.',
          '',
          moodContext
        ].join('\n')
      }
    ], {
      temperature: 0.35,
      maxTokens: 1000
    });

    const suggestions = parseSuggestionsJson(content);
    if (suggestions.length === 0) {
      throw new Error('GigaChat returned empty suggestions');
    }

    return suggestions;
  } catch (error) {
    console.error('Error generating GigaChat suggestions:', error.message);
    if (error instanceof AiProviderError) {
      throw error;
    }

    throw new AiProviderError('GigaChat suggestions request failed', 502, error);
  }
};

const generateResponse = async (message, userId, conversationMessages = []) => {
  const recentMoods = await getRecentMoods(userId, 14);
  const moodContext = getMoodContext(recentMoods);
  const history = normalizeConversationMessages(conversationMessages, message);

  return callGigaChat([
    {
      role: 'system',
      content: `${AI_ASSISTANT_SYSTEM_PROMPT}\n\nКонтекст дневника пользователя:\n${moodContext}`
    },
    ...history
  ], {
    temperature: 0.6,
    maxTokens: 1400
  });
};

module.exports = {
  AiProviderError,
  getPersonalizedSuggestions,
  generateResponse
};
