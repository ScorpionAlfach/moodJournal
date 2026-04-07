const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { auth } = require('../middleware/auth');
const Conversation = require('../models/Conversation');
const { getPersonalizedSuggestions, generateResponse } = require('../services/aiService');

const router = express.Router();

// POST /api/ai/chat - Send message to AI
router.post('/chat',
  auth,
  [
    body('message').trim().notEmpty().withMessage('Введите сообщение').isLength({ max: 2000 }),
    body('conversationId').optional().trim()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const userId = req.user._id;
      const { message, conversationId } = req.body;

      let conversation;

      if (conversationId) {
        // Find existing conversation
        conversation = await Conversation.findOne({
          _id: conversationId,
          userId
        });
      }

      if (!conversation) {
        // Create new conversation
        conversation = new Conversation({
          userId,
          messages: []
        });
      }

      // Add user message
      const userMessage = {
        role: 'user',
        content: message,
        timestamp: new Date()
      };
      conversation.messages.push(userMessage);

      // Generate AI response
      const responseContent = await generateResponse(message, userId);

      // Add assistant message
      const assistantMessage = {
        role: 'assistant',
        content: responseContent,
        timestamp: new Date()
      };
      conversation.messages.push(assistantMessage);

      await conversation.save();

      // Format response
      const lastMessage = conversation.messages[conversation.messages.length - 1];

      res.json({
        message: {
          id: lastMessage._id.toString(),
          role: lastMessage.role,
          content: lastMessage.content,
          timestamp: lastMessage.timestamp
        },
        conversationId: conversation._id.toString()
      });
    } catch (error) {
      console.error('AI chat error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// GET /api/ai/suggestions - Get personalized suggestions
router.get('/suggestions', auth, async (req, res) => {
  try {
    const suggestions = await getPersonalizedSuggestions(req.user._id);

    res.json({ suggestions });
  } catch (error) {
    console.error('Get suggestions error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// GET /api/ai/conversations - Get user's conversations
router.get('/conversations', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({ userId: req.user._id })
      .sort({ updatedAt: -1 })
      .limit(10);

    res.json({
      conversations: conversations.map(c => ({
        id: c._id.toString(),
        lastMessage: c.messages[c.messages.length - 1]?.content || '',
        updatedAt: c.updatedAt
      }))
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
