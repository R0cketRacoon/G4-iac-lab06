// Valida que cada mensaje siga Conventional Commits 1.0.0:
//   <tipo>(<ámbito opcional>): <descripción>
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [
      1,
      'always',
      [
        'bootstrap', 'red', 'seguridad', 'endpoints', 'almacenamiento',
        'mensajeria', 'iam', 'observabilidad', 'computo', 'api',
        'entornos', 'dev', 'qa', 'prod', 'app', 'docker', 'scripts',
        'ci', 'docs', 'evidencias', 'deps',
      ],
    ],
    'header-max-length': [2, 'always', 100],
  },
};
