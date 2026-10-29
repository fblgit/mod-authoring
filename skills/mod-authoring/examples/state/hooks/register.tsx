import { atom, read, update } from 'claude-code'
import type { Engine, Register } from 'claude-code'

const PANE = 'state-counter'
const count = atom({ plugin: 'state-counter', key: 'count' } as const, 0)

// $.state resets on /clear /resume /branch; the store keeps the value.
async function loadSaved($: Engine) {
  const saved = await $.store.get('count')
  if (typeof saved === 'number') await update($, count, () => saved)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'state-counter', description: 'Open the counter pane' })
    await loadSaved($)
    return next(e)
  })

  on('classic.SessionStart', { source: ['clear', 'resume', 'fork'] }, async ($, e, next) => {
    await loadSaved($)
    return next(e)
  })

  on('command.run', { command: 'state-counter' }, async $ => {
    await $.ui.open({ id: PANE, title: 'Counter' })
    return { text: 'Counter pane opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const n = await read($, count)
    return (
      <Box flexDirection="column">
        <Text>Count: {n}</Text>
        <Button
          key="inc"
          label="Add one"
          onPress={async () => {
            const next = (await read($, count)) + 1
            await update($, count, () => next)
            await $.store.set('count', next)
          }}
        />
      </Box>
    )
  })
}
