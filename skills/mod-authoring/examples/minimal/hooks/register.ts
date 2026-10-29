import type { Register } from 'claude-code'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'minimal', description: 'Print a line' })
    return next(e)
  })

  on('command.run', { command: 'minimal' }, async () => {
    return { text: 'Hello from the minimal mod' }
  })
}
