goog.provide 'app.user.Store'

goog.require 'app.songs.Song'
goog.require 'este.labs.Store'
goog.require 'goog.array'

class app.user.Store extends este.labs.Store

  ###*
    @constructor
    @extends {este.labs.Store}
  ###
  constructor: ->
    super 'user'
    @setEmpty()

  ###*
    @type {Array.<app.songs.Song>}
  ###
  songs: null

  ###*
    @type {app.songs.Song}
  ###
  newSong: null

  ###*
    @type {Object}
  ###
  user: null

  setEmpty: ->
    @songs = []
    @newSong = new app.songs.Song
    @user = null

  ###*
    @return {Array.<app.songs.Song>}
  ###
  allSongs: ->
    goog.array.sortObjectsByKey @songs, 'name'
    @songs

  ###*
    @return {Array.<app.ValidationError>}
  ###
  addNewSong: ->
    errors = @newSong.validate()
    if @contains @newSong
      errors.push new app.ValidationError 'name',
        'Song with such name and artist already exists.'
    return errors if errors.length
    @songs.push @newSong
    @newSong = new app.songs.Song
    @notify()
    []

  ###*
    @param {app.songs.Song} song
  ###
  delete: (song) ->
    goog.array.remove @songs, song
    @notify()

  ###*
    @param {este.Route} route
    @return {app.songs.Song}
  ###
  songByRoute: (route) ->
    goog.array.find @songs, (song) -> song.id == route.params.id

  ###*
    @param {app.songs.Song} song
    @return {boolean}
  ###
  contains: (song) ->
    goog.array.some @songs, (s) ->
      s.name == song.name &&
      s.artist == song.artist

  ###*
    @param {app.songs.Song} song
    @param {string} prop
    @param {string} value
  ###
  updateSong: (song, prop, value) ->
    song[prop] = value
    song.update()
    @notify()

  ###*
    @override
  ###
  toJson: ->
    newSong: @newSong
    songs: @asObject @songs
    user: @getJsonUser @user

  ###*
    @override
  ###
  fromJson: (json) ->
    @newSong = @instanceFromJson app.songs.Song, json.newSong
    @user = @getJsonUser json.user
    # NOTE(steida): Because JSON stringify and parse ignore empty array.
    @songs = (@asArray(json.songs) || []).map @instanceFromJson app.songs.Song

  getJsonUser: (user) ->
    return null if !user
    displayName: user.displayName
    id: user.id
    provider: user.provider
    thirdPartyUserData: user.thirdPartyUserData
    uid: user.uid