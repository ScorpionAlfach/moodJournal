const https = require('https');
const { GigaChat } = require('gigachat');

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

const getPersonalizedSuggestions = async () => [
  {
    id: 'breathing_pause',
    title: 'Короткая пауза',
    content: 'Сделайте 5 спокойных вдохов и выдохов, отмечая ощущения в теле.',
    category: 'mindfulness',
    icon: FALLBACK_ICON_BY_CATEGORY.mindfulness
  },
  {
    id: 'sleep_routine',
    title: 'Ритуал сна',
    content: 'За 30 минут до сна уберите экран и запишите одну мысль, которую хотите отпустить.',
    category: 'sleep',
    icon: FALLBACK_ICON_BY_CATEGORY.sleep
  },
  {
    id: 'small_walk',
    title: 'Небольшое движение',
    content: 'Пройдитесь 10 минут или сделайте легкую разминку, чтобы переключить внимание.',
    category: 'activity',
    icon: FALLBACK_ICON_BY_CATEGORY.activity
  }
];

const generateResponse = async (message, conversationMessages = []) => {
  const history = normalizeConversationMessages(conversationMessages, message);

  return callGigaChat([
    {
      role: 'system',
      content: AI_ASSISTANT_SYSTEM_PROMPT
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
