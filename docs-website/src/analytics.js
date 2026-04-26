import posthog from 'posthog-js'

const isLocalhost =
  window.location.host.includes('127.0.0.1') ||
  window.location.host.includes('localhost')

if (!isLocalhost) {
  posthog.init(import.meta.env.VITE_POSTHOG_KEY, {
    api_host: import.meta.env.VITE_POSTHOG_HOST,
    defaults: '2026-01-30',
    capture_pageview: 'history_change',
  })
}

export function capture(event, properties) {
  posthog.capture(event, properties)
}

export { posthog }
