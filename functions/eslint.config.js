// ESLint v9+ flat config migration for Cloud Functions
import globals from "globals";

export default [
  {
    files: ["**/*.js"],
    languageOptions: {
      globals: globals.node,
      ecmaVersion: 2018,
    },
    rules: {
      "no-restricted-globals": ["error", "name", "length"],
      "prefer-arrow-callback": "error",
      "quotes": ["error", "double", { allowTemplateLiterals: true }],
    },
  },
  {
    files: ["**/*.spec.*"],
    languageOptions: {
      globals: { mocha: true },
    },
    rules: {},
  },
];
