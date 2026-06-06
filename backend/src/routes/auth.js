const express = require('express');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken, auth } = require('../middleware/auth');

const router = express.Router();

const CODE_TTL_MINUTES = 10;

const hashCode = (code) => crypto
  .createHmac('sha256', process.env.JWT_SECRET || 'development-secret')
  .update(String(code))
  .digest('hex');

const generateVerificationCode = () => String(Math.floor(100000 + Math.random() * 900000));

const isProfileComplete = (user) => Boolean(
  user.firstName &&
  user.lastName &&
  user.phone &&
  user.age
);

const createMailTransport = () => {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS) {
    throw new Error('SMTP settings are missing');
  }

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: Number(SMTP_PORT),
    secure: Number(SMTP_PORT) === 465,
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS
    }
  });
};

const sendVerificationCode = async (email, code) => {
  const from = process.env.SMTP_FROM || process.env.SMTP_USER;
  const transport = createMailTransport();

  await transport.sendMail({
    from,
    to: email,
    subject: 'Код подтверждения MoodJournal',
    text: `Ваш код подтверждения: ${code}\n\nКод действителен ${CODE_TTL_MINUTES} минут.`,
    html: `
      <p>Ваш код подтверждения:</p>
      <p style="font-size:24px;font-weight:700;letter-spacing:4px">${code}</p>
      <p>Код действителен ${CODE_TTL_MINUTES} минут.</p>
    `
  });
};

const setVerificationCode = async (user) => {
  const code = generateVerificationCode();
  user.verificationCodeHash = hashCode(code);
  user.verificationCodeExpiry = new Date(Date.now() + CODE_TTL_MINUTES * 60 * 1000);
  await user.save();
  await sendVerificationCode(user.email, code);
};

const verifyCodeForUser = (user, code) => {
  if (!user.verificationCodeHash || !user.verificationCodeExpiry) {
    return false;
  }

  if (new Date() > user.verificationCodeExpiry) {
    return false;
  }

  return user.verificationCodeHash === hashCode(code);
};

const clearVerificationCode = (user) => {
  user.verificationCodeHash = null;
  user.verificationCodeExpiry = null;
};

// POST /api/auth/register - Send email verification code
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
      let user = await User.findOne({ email });

      if (!user) {
        user = new User({ email });
      }

      await setVerificationCode(user);

      res.json({
        message: 'Код подтверждения отправлен на email',
        email,
        codeExpiresInMinutes: CODE_TTL_MINUTES
      });
    } catch (error) {
      console.error('Register error:', error);
      if (error.message === 'SMTP settings are missing') {
        return res.status(500).json({ message: 'SMTP не настроен' });
      }
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/verify-code - Verify email code and login existing users
router.post('/verify-code',
  [
    body('email').isEmail().normalizeEmail(),
    body('code').isLength({ min: 6, max: 6 }).isNumeric().withMessage('Введите 6-значный код')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email, code } = req.body;
      const user = await User.findOne({ email });

      if (!user || !verifyCodeForUser(user, code)) {
        return res.status(400).json({ message: 'Неверный или истёкший код' });
      }

      if (!user.isVerified || !isProfileComplete(user)) {
        return res.json({
          message: 'Заполните профиль для завершения регистрации',
          email,
          isNewUser: true
        });
      }

      clearVerificationCode(user);
      await user.save();

      const token = generateToken(user._id);
      res.json({
        message: 'Вход выполнен успешно',
        email,
        isNewUser: false,
        token,
        user: user.toJSON()
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
    body('code').isLength({ min: 6, max: 6 }).isNumeric().withMessage('Введите 6-значный код'),
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

      let user = await User.findOne({ email });

      if (!user) {
        return res.status(400).json({ message: 'Сначала запросите код подтверждения' });
      }

      if (!verifyCodeForUser(user, code)) {
        return res.status(400).json({ message: 'Неверный или истёкший код' });
      }

      user.firstName = firstName;
      user.lastName = lastName;
      user.phone = phone;
      user.age = age;
      user.gender = gender;
      user.isVerified = true;
      clearVerificationCode(user);

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

// POST /api/auth/login - Send login code for existing users
router.post('/login',
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

      const user = await User.findOne({ email });

      if (!user) {
        return res.status(404).json({ message: 'Пользователь не найден' });
      }

      if (!user.isVerified) {
        return res.status(400).json({ message: 'Завершите регистрацию' });
      }

      await setVerificationCode(user);

      res.json({
        message: 'Код подтверждения отправлен на email',
        email,
        codeExpiresInMinutes: CODE_TTL_MINUTES
      });
    } catch (error) {
      console.error('Login error:', error);
      if (error.message === 'SMTP settings are missing') {
        return res.status(500).json({ message: 'SMTP не настроен' });
      }
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
