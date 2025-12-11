module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
  },
  ignorePatterns: [
    "node_modules/",
    "dist/",
    "build/",
    "coverage/"
  ],
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: "module"
  },
  overrides: [
    {
      files: ["**/*.ts"],
      parser: "@typescript-eslint/parser",
      plugins: ["@typescript-eslint"],
      extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended"
      ]
    },
    {
      files: ["**/*.js"],
      extends: ["eslint:recommended"]
    }
  ],
  rules: {
    "no-unused-vars": "warn",
    "no-undef": "error"
  }
};
