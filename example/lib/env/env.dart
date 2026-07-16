import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', requireEnvFile: true)
abstract final class Env {
  @EnviedField(varName: 'OPENAI_API_KEY', defaultValue: '', obfuscate: true)
  static final String openaiApiKey = _Env.openaiApiKey;

  @EnviedField(varName: 'OPENAI_MODEL', defaultValue: 'gpt-4.1')
  static final String openaiModel = _Env.openaiModel;

  @EnviedField(varName: 'OPENAI_ENDPOINT', defaultValue: '')
  static final String openaiEndpoint = _Env.openaiEndpoint;
}
