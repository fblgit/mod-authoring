import { expect, test } from 'claude-code/testing'

test('greet registers on session start and answers', async ($, on) => {
  on('command.register', () => ({ value: { command: 'greet' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  const out = await $.command.run({ command: 'greet' })

  expect(out.text).toBe('Hello')
})
