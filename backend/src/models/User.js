const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  age: {
    type: Number,
    required: true,
    min: 13,
    max: 120
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say'],
    default: 'prefer_not_to_say'
  },
  avatarURL: {
    type: String,
    default: null
  },
  onboardingCompleted: {
    type: Boolean,
    default: false
  },
  verificationCode: {
    type: String,
    default: null
  },
  verificationCodeExpires: {
    type: Date,
    default: null
  },
  isVerified: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

userSchema.methods.generateVerificationCode = async function() {
  const code = crypto.randomInt(100000, 999999).toString();
  const salt = await bcrypt.genSalt(10);
  this.verificationCode = await bcrypt.hash(code, salt);
  this.verificationCodeExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return code;
};

userSchema.methods.verifyCode = async function(code) {
  if (!this.verificationCode || !this.verificationCodeExpires) {
    return false;
  }
  if (new Date() > this.verificationCodeExpires) {
    return false;
  }
  return bcrypt.compare(code, this.verificationCode);
};

userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.verificationCode;
  delete obj.verificationCodeExpires;
  delete obj.__v;
  obj.id = obj._id;
  delete obj._id;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
