import type { Register } from 'claude-code'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'greet', description: 'Print a greeting' })
    return next(e)
  })

  on('command.run', { command: 'greet' }, async () => ({ text: 'Hello' }))
}
