const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken, auth } = require('../middleware/auth');
const { sendVerificationEmail } = require('../services/emailService');

const router = express.Router();

// POST /api/auth/register - Send verification code to email
router.post('/register',
  [
    body('email').isEmail().normalizeEmail().withMessage('Введите корректный email')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email } = req.body;

      // Find or create user
      let user = await User.findOne({ email });

      if (!user) {
        user = new User({
          email,
          firstName: 'Новый',
          lastName: 'Пользователь',
          phone: '+70000000000',
          age: 18
        });
      }

      // Generate and save verification code
      const code = user.generateVerificationCode();
      await user.save();

      // Send email
      await sendVerificationEmail(email, code);

      res.json({
        message: 'Код подтверждения отправлен на email',
        email
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/verify-code - Verify the code
router.post('/verify-code',
  [
    body('email').isEmail().normalizeEmail(),
    body('code').isLength({ min: 6, max: 6 }).withMessage('Код должен содержать 6 цифр')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email, code } = req.body;

      const user = await User.findOne({ email });

      if (!user) {
        return res.status(404).json({ message: 'Пользователь не найден' });
      }

      if (!user.verifyCode(code)) {
        return res.status(400).json({ message: 'Неверный или истёкший код' });
      }

      res.json({
        success: true,
        message: 'Код подтверждён'
      });
    } catch (error) {
      console.error('Verify code error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/complete-registration - Complete registration with user data
router.post('/complete-registration',
  [
    body('email').isEmail().normalizeEmail(),
    body('code').isLength({ min: 6, max: 6 }),
    body('firstName').trim().notEmpty().withMessage('Введите имя'),
    body('lastName').trim().notEmpty().withMessage('Введите фамилию'),
    body('phone').trim().notEmpty().withMessage('Введите телефон'),
    body('age').isInt({ min: 13, max: 120 }).withMessage('Возраст должен быть от 13 до 120'),
    body('gender').isIn(['male', 'female', 'other', 'prefer_not_to_say'])
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email, code, firstName, lastName, phone, age, gender } = req.body;

      const user = await User.findOne({ email });

      if (!user) {
        return res.status(404).json({ message: 'Пользователь не найден' });
      }

      if (!user.verifyCode(code)) {
        return res.status(400).json({ message: 'Неверный или истёкший код' });
      }

      // Update user data
      user.firstName = firstName;
      user.lastName = lastName;
      user.phone = phone;
      user.age = age;
      user.gender = gender;
      user.isVerified = true;
      user.verificationCode = null;
      user.verificationCodeExpires = null;

      await user.save();

      const token = generateToken(user._id);

      res.json({
        token,
        user: user.toJSON()
      });
    } catch (error) {
      console.error('Complete registration error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/login - Login with email and code
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('code').isLength({ min: 6, max: 6 })
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email, code } = req.body;

      const user = await User.findOne({ email });

      if (!user) {
        return res.status(404).json({ message: 'Пользователь не найден' });
      }

      if (!user.verifyCode(code)) {
        return res.status(400).json({ message: 'Неверный или истёкший код' });
      }

      // Clear verification code
      user.verificationCode = null;
      user.verificationCodeExpires = null;
      await user.save();

      const token = generateToken(user._id);

      res.json({
        token,
        user: user.toJSON()
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/logout
router.post('/logout', auth, async (req, res) => {
  try {
    // In a real app, you might want to blacklist the token
    res.json({ message: 'Выход выполнен успешно' });
  } catch (error) {
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
