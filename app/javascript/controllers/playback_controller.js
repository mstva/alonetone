import { Controller } from 'stimulus'
import { Howl } from 'howler'

// Hack for Safari 12 https://github.com/goldfire/howler.js/pull/1047
const safari = /safari/.test(Howler._navigator && Howler._navigator.userAgent.toLowerCase())
//if (safari) Howler._canPlayEvent = 'loadedmetadata' 


let player

export default class extends Controller {
  static targets = ['play', 'title', 'seekBarContainer', 'seekBarLoaded']

  initialize() {
    this.preInitialize()
    this.loaded = false
    this.isPlaying = false
    this.nextTrackLoading = false
    this.setupHowl()
  }

  disconnect() {
    if (this.sound.playing()) {
      this.sound.pause()
    }
  }

  setupHowl() {
    const controller = this
    this.sound = new Howl({
      src: Array(this.url),
      html5: true,
      preload: this.preload,
      // onend: controller.playNextTrack.bind(controller),
      onplay() {
        requestAnimationFrame(controller.whilePlaying.bind(controller))
      },
      onseek() {
        requestAnimationFrame(controller.whilePlaying.bind(controller))
      },
      onplayerror(id, e) {
        console.log(e)
        controller.pause()
      }
    })
  }

  // Called once by the howler onplay/onseek callbacks
  // and recurses to give us a way to update throughout playback
  whilePlaying() {
    this.position = this.sound.seek()
    if (this.sound.playing()) {
      this.whilePlayingCallback()
      if (!this.nextTrackLoading && this.positionFromEnd(10000)) {
        this.preloadNextTrack()
        this.nextTrackLoading = true
      }
      if (this.positionFromEnd(200)) {
        this.playNextTrack()
      } else {
        // we don't want to update this 60 times a second, at most 10
        setTimeout(() => requestAnimationFrame(this.whilePlaying.bind(this)), 100)
      }
    }
    this.calculateTime()
  }

  // called immedately by js
  play() {
    this.sound.play()
    console.log('sound.play!')
    this.isPlaying = true
    if (player) {
      player.pause()
    }
    player = this
    this.element.classList.add('playing')
    this.playCallback()
  }

  pause() {
    this.sound.pause()
    player = null
    this.isPlaying = false
    this.pauseCallback()
  }

  togglePlay(e) {
    e.preventDefault()
    if (this.isPlaying) {
      this.pause()
    } else {
      this.play()
    }
  }

  nextTrack() {
    const next = this.element.nextElementSibling
    return this.application.getControllerForElementAndIdentifier(next, this.identifier)
  }

  playNextTrack() {
    if (this.nextTrack) this.nextTrack.play()
  }

  preloadNextTrack() {
    this.nextTrack = this.nextTrack()
    if (this.nextTrack) this.nextTrack.sound.load()
  }

  seek(newPosition) {
    if (!this.isPlaying) this.play()
    this.sound.seek(this.sound.duration() * newPosition)
  }

  positionFromEnd(ms) {
    const positionFromEnd = (this.sound.duration() - this.position) * 1000
    return ms > positionFromEnd
  }

  percentPlayed() {
    return this.position / this.sound.duration()
  }

  calculateTime() {
    const time = Math.floor(this.position)
    const min = Math.floor(time / 60) 
    const sec = time % 60
    this.time = min + ':' + (sec >= 10 ? sec : '0' + sec)
  }
}
