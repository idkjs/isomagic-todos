module.exports = {
  mode: 'development',
  entry: './lib/js/src/client/app.js',
  output: {
    path: __dirname +'/public',
    filename: 'bundle.js',
  },
};
