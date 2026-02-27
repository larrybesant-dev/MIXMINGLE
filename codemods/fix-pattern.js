# Codemod Example: Fix Common Patterns

// Example codemod for jscodeshift
module.exports = function(fileInfo, api) {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);

  // Example: Replace deprecated function calls
  root.find(j.CallExpression, {
    callee: { name: 'oldFunction' }
  }).forEach(path => {
    j(path).replaceWith(
      j.callExpression(j.identifier('newFunction'), path.value.arguments)
    );
  });

  // Example: Fix import paths
  root.find(j.ImportDeclaration, {
    source: { value: './old-path' }
  }).forEach(path => {
    path.value.source.value = './new-path';
  });

  return root.toSource();
};
