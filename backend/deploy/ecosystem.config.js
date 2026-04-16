module.exports = {
  apps: [{
    name: 'mood-journal',
    script: 'src/index.js',
    cwd: '/var/www/mood-journal/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '256M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
