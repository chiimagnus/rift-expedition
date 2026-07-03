import test from 'node:test'
import assert from 'node:assert/strict'
import { PATH_ALIAS_PROBE } from '@models/pathAliasProbe'

test('M0: @models/* 路径别名可在测试运行器中解析', () => {
  assert.equal(PATH_ALIAS_PROBE, true)
})
