expect = require('chai').expect
sinon = require('sinon')

fs = require('fs')
path = require('path')
rimraf = require('rimraf')

watchGlob = require('../src/index.coffee')

describe 'watch-glob', ->

  delay = (t, f) -> setTimeout(f,t)
  delayForWatch = (f) -> delay(500, f)

  testFilePath = (f = '') -> path.normalize(path.join(__dirname, 'tmp', f))

  spyAdded = null
  spyRemoved = null

  before ->
    rimraf.sync(testFilePath())
    try fs.mkdirSync(testFilePath())
  #after -> rimraf.sync(testFilePath())


  beforeEach (done) ->
    fs.writeFileSync(testFilePath('f1.txt'), '')
    spyAdded = sinon.spy()
    spyRemoved = sinon.spy()
    delayForWatch(done)

    
  it 'should call `addedCallback` when file changes', (done) ->
    w = watchGlob('test/tmp/f1.txt', { }, spyAdded, spyRemoved)
    fs.writeFileSync(testFilePath('f1.txt'), 'test')
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(1)
      expect(spyAdded.firstCall.args[0]).to.have.property('relative').that.equals(path.normalize('test/tmp/f1.txt'))
      expect(spyAdded.firstCall.args[0]).to.have.property('base').that.equals(path.normalize(process.cwd()))
      expect(spyAdded.firstCall.args[0]).to.have.property('path').that.equals(testFilePath('f1.txt'))
      expect(spyRemoved.callCount).to.equal(0)
      w.destroy()
      done()

  it 'should not call after destroy', (done) ->
    w = watchGlob('test/tmp/f1.txt', { }, spyAdded, spyRemoved)
    w.destroy()
    fs.writeFileSync(testFilePath('f1.txt'), 'test')
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(0)
      expect(spyRemoved.callCount).to.equal(0)
      done()

  it 'should call `addedCallback` when file is added', (done) ->
    w = watchGlob('test/tmp/*', { }, spyAdded, spyRemoved)
    fs.writeFileSync(testFilePath('added1.txt'), 'test')
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(1)
      expect(spyAdded.firstCall.args[0].relative).to.equal(path.normalize('test/tmp/added1.txt'))
      expect(spyRemoved.callCount).to.equal(0)
      w.destroy()
      done()

  it 'should call `addedCallback` when file is "created" through rename', (done) ->
    fs.writeFileSync(testFilePath('torename1.txt'), 'test')
    w = watchGlob('test/tmp/*', { }, spyAdded, spyRemoved)
    fs.renameSync(testFilePath('torename1.txt'), testFilePath('renamed1.txt'))
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(1)
      expect(spyAdded.firstCall.args[0].relative).to.equal(path.normalize('test/tmp/renamed1.txt'))
      w.destroy()
      done()

  it 'should call `removedCallback` when file is "deleted" through rename', (done) ->
    fs.writeFileSync(testFilePath('torename1.txt'), 'test')
    w = watchGlob('test/tmp/torename*', { }, spyAdded, spyRemoved)
    fs.renameSync(testFilePath('torename1.txt'), testFilePath('renamed1.txt'))
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(0)
      expect(spyRemoved.callCount).to.equal(1)
      expect(spyRemoved.firstCall.args[0].relative).to.equal(path.normalize('test/tmp/torename1.txt'))
      w.destroy()
      done()


  it 'should call `removedCallback` when file is deleted', (done) ->
    fs.writeFileSync(testFilePath('todelete1.txt'), 'test')
    w = watchGlob('test/tmp/todelete*', { }, spyAdded, spyRemoved)
    fs.unlinkSync(testFilePath('todelete1.txt'))
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(0)
      expect(spyRemoved.callCount).to.equal(1)
      expect(spyRemoved.firstCall.args[0].relative).to.equal(path.normalize('test/tmp/todelete1.txt'))
      w.destroy()
      done()

  it 'should work when `options` is not specified', (done) ->
    w = watchGlob('test/tmp/f1.txt', spyAdded, spyRemoved)
    fs.writeFileSync(testFilePath('f1.txt'), 'test')
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(1)
      expect(spyRemoved.callCount).to.equal(0)
      w.destroy()
      done()

  it 'should receive `cwd` option', (done) ->
    w = watchGlob('f1.txt', { cwd: testFilePath() }, spyAdded, spyRemoved)
    fs.writeFileSync(testFilePath('f1.txt'), 'test')
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(1)
      expect(spyAdded.firstCall.args[0]).to.have.property('relative').that.equals('f1.txt')
      expect(spyAdded.firstCall.args[0]).to.have.property('base').that.equals(testFilePath())
      expect(spyAdded.firstCall.args[0]).to.have.property('path').that.equals(testFilePath('f1.txt'))
      expect(spyRemoved.callCount).to.equal(0)
      w.destroy()
      done()    


  it 'should not trigger on subdirectory create which does not match pattern', (done) ->
    w = watchGlob('test/tmp/**/*.txt', { }, spyAdded, spyRemoved)
    fs.mkdirSync(testFilePath('subdir'))
    delayForWatch ->
      expect(spyAdded.callCount).to.equal(0)
      expect(spyRemoved.callCount).to.equal(0)
      w.destroy()
      done()

  describe 'callbackArg', ->
    it 'should support `relative`', (done) ->
      w = watchGlob('test/tmp/f1.txt', { callbackArg: 'relative' }, spyAdded, spyRemoved)
      fs.writeFileSync(testFilePath('f1.txt'), 'test')
      delayForWatch ->
        expect(spyAdded.callCount).to.equal(1)
        expect(spyAdded.firstCall.args[0]).to.equal(path.normalize('test/tmp/f1.txt'))
        w.destroy()
        done()

    it 'should support `absolute`', (done) ->
      w = watchGlob('test/tmp/f1.txt', { callbackArg: 'absolute' }, spyAdded, spyRemoved)
      fs.writeFileSync(testFilePath('f1.txt'), 'test')
      delayForWatch ->
        expect(spyAdded.callCount).to.equal(1)
        expect(spyAdded.firstCall.args[0]).to.equal(testFilePath('f1.txt'))
        w.destroy()
        done()

    it 'should support `vinyl`', (done) ->
      w = watchGlob('test/tmp/f1.txt', { callbackArg: 'vinyl' }, spyAdded, spyRemoved)
      fs.writeFileSync(testFilePath('f1.txt'), 'test')
      delayForWatch ->
        expect(spyAdded.callCount).to.equal(1)
        expect(spyAdded.firstCall.args[0]).to.have.property('relative').that.equals(path.normalize('test/tmp/f1.txt'))
        expect(spyAdded.firstCall.args[0]).to.have.property('base').that.equals(path.normalize(process.cwd()))
        expect(spyAdded.firstCall.args[0]).to.have.property('path').that.equals(testFilePath('f1.txt'))
        done()
