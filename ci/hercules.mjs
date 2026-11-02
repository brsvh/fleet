export function deployHandler(host) {
  return (
    'deploy'
    + host.replace(/(?:^|-)([a-z0-9])/g, (_, letter) => letter.toUpperCase())
  );
}
