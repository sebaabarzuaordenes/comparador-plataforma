const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

const config = {
  transformer: {
    babelTransformerPath: require.resolve('./metro.txt-transformer.js'),
  },
  resolver: {
    assetExts: defaultConfig.resolver.assetExts.filter(ext => ext !== 'txt'),
    sourceExts: [...defaultConfig.resolver.sourceExts, 'txt'],
  },
};

module.exports = mergeConfig(defaultConfig, config);
