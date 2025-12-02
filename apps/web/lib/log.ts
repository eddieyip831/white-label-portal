type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'silent';

const LEVEL_ORDER: LogLevel[] = ['debug', 'info', 'warn', 'error', 'silent'];

function getEnvLogLevel(): LogLevel {
  // Client-safe env for browser bundles
  const clientLevel = process.env.NEXT_PUBLIC_LOG_LEVEL as LogLevel | undefined;
  const serverLevel = process.env.LOG_LEVEL as LogLevel | undefined;

  const raw =
    clientLevel ||
    serverLevel ||
    (process.env.NODE_ENV === 'development' ? 'debug' : 'warn');

  return LEVEL_ORDER.includes(raw as LogLevel) ? (raw as LogLevel) : 'warn';
}

const EFFECTIVE_LEVEL = getEnvLogLevel();

function shouldLog(level: LogLevel) {
  return (
    LEVEL_ORDER.indexOf(level) >= 0 &&
    LEVEL_ORDER.indexOf(level) >= LEVEL_ORDER.indexOf(EFFECTIVE_LEVEL)
  );
}

export function log(
  level: LogLevel,
  scope: string,
  message: string,
  extra?: unknown,
) {
  if (!shouldLog(level)) return;

  const prefix = `[${scope}] ${message}`;

  switch (level) {
    case 'debug':
    case 'info':
      // eslint-disable-next-line no-console
      console.log(prefix, extra ?? '');
      break;
    case 'warn':
      // eslint-disable-next-line no-console
      console.warn(prefix, extra ?? '');
      break;
    case 'error':
      // eslint-disable-next-line no-console
      console.error(prefix, extra ?? '');
      break;
    case 'silent':
    default:
      break;
  }
}

export const logDebug = (scope: string, msg: string, extra?: unknown) =>
  log('debug', scope, msg, extra);
export const logInfo = (scope: string, msg: string, extra?: unknown) =>
  log('info', scope, msg, extra);
export const logWarn = (scope: string, msg: string, extra?: unknown) =>
  log('warn', scope, msg, extra);
export const logError = (scope: string, msg: string, extra?: unknown) =>
  log('error', scope, msg, extra);
