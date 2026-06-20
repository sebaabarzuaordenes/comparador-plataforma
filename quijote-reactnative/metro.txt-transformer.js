const upstreamTransformer = require('@react-native/metro-babel-transformer');
const path = require('path');

module.exports.transform = function transform({src, filename, options}) {
  if (path.extname(filename) === '.txt') {
    return upstreamTransformer.transform({
      src: `module.exports = ${JSON.stringify(src)};`,
      filename: `${filename}.js`,
      options,
    });
  }

  return upstreamTransformer.transform({src, filename, options});
};

module.exports.getCacheKey = upstreamTransformer.getCacheKey;
