const nodemailer = require('nodemailer');

// Create transporter
const createTransporter = () => {
  // For development, use ethereal email or console log
  if (process.env.NODE_ENV === 'development' && !process.env.SMTP_USER) {
    return null;
  }

  const port = parseInt(process.env.SMTP_PORT) || 465;

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.yandex.ru',
    port: port,
    secure: port === 465, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
};

const sendVerificationEmail = async (email, code) => {
  // Временно: выводим код в консоль вместо отправки email
  console.log(`\n========================================`);
  console.log(`Verification code for ${email}: ${code}`);
  console.log(`========================================\n`);

  // Раскомментируйте для включения email:
  // const transporter = createTransporter();
  // if (transporter) {
  //   await transporter.sendMail(mailOptions);
  // }
  return;

  const transporter = createTransporter();

  const mailOptions = {
    from: `"Дневник настроения" <${process.env.SMTP_USER || 'noreply@moodjournal.app'}>`,
    to: email,
    subject: 'Код подтверждения',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
          .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
          .header { text-align: center; margin-bottom: 40px; }
          .logo { width: 80px; height: 80px; background: linear-gradient(135deg, #6366F1, #8B5CF6); border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; }
          .code-box { background: #F8FAFC; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
          .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #6366F1; }
          .footer { text-align: center; color: #64748B; font-size: 14px; margin-top: 40px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">
              <span style="font-size: 40px;">😊</span>
            </div>
            <h1 style="color: #1E293B; margin-top: 20px;">Дневник настроения</h1>
          </div>

          <p style="color: #1E293B; font-size: 16px;">Здравствуйте!</p>
          <p style="color: #64748B; font-size: 16px;">Ваш код подтверждения:</p>

          <div class="code-box">
            <div class="code">${code}</div>
          </div>

          <p style="color: #64748B; font-size: 14px;">
            Код действителен в течение 10 минут. Если вы не запрашивали этот код, просто проигнорируйте это письмо.
          </p>

          <div class="footer">
            <p>© 2024 Дневник настроения. Все права защищены.</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  if (transporter) {
    try {
      await transporter.sendMail(mailOptions);
      console.log(`Verification email sent to ${email}`);
    } catch (error) {
      console.error('Error sending email:', error);
      throw new Error('Не удалось отправить email');
    }
  } else {
    // Development mode - just log the code
    console.log(`\n========================================`);
    console.log(`Verification code for ${email}: ${code}`);
    console.log(`========================================\n`);
  }
};

module.exports = { sendVerificationEmail };
