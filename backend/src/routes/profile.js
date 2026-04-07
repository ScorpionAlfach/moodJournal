const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Mood = require('../models/Mood');
const Note = require('../models/Note');
const Conversation = require('../models/Conversation');

const router = express.Router();

// GET /api/profile - Get user profile
router.get('/', auth, async (req, res) => {
  try {
    res.json(req.user.toJSON());
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// PUT /api/profile - Update profile
router.put('/',
  auth,
  [
    body('firstName').optional().trim().notEmpty(),
    body('lastName').optional().trim().notEmpty(),
    body('phone').optional().trim().notEmpty(),
    body('age').optional().isInt({ min: 13, max: 120 }),
    body('gender').optional().isIn(['male', 'female', 'other', 'prefer_not_to_say'])
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { firstName, lastName, phone, age, gender } = req.body;
      const user = req.user;

      if (firstName) user.firstName = firstName;
      if (lastName) user.lastName = lastName;
      if (phone) user.phone = phone;
      if (age) user.age = age;
      if (gender) user.gender = gender;

      await user.save();

      res.json(user.toJSON());
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// DELETE /api/profile - Delete profile and all user data
router.delete('/', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    // Delete all user data
    await Promise.all([
      Mood.deleteMany({ userId }),
      Note.deleteMany({ userId }),
      Conversation.deleteMany({ userId }),
      req.user.deleteOne()
    ]);

    res.json({ message: 'Аккаунт удалён' });
  } catch (error) {
    console.error('Delete profile error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
