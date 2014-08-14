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

  # ###*
  #   TODO(steida): If ok, move to este.labs.Store.
  #   @type {?number}
  # ###
  # created: null
  #
  # ###*
  #   TODO(steida): If ok, move to este.labs.Store.
  #   @type {?number}
  # ###
  # updated: null

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
    @param {string} id
    @return {app.songs.Song}
  ###
  songById: (id) ->
    goog.array.find @songs, (song) -> song.id == id

  ###*
    @param {este.Route} route
    @return {app.songs.Song}
  ###
  songByRoute: (route) ->
    @songById route.params.id

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
    # created: @created
    newSong: @newSong
    songs: @asObject @songs
    # updated: @updated
    user: @getJsonUser @user

  ###*
    @override
  ###
  fromJson: (json) ->
    # @created = json.created
    @newSong = @instanceFromJson app.songs.Song, json.newSong
    # NOTE(steida): '|| []'' because JSON stringify and parse ignores empty array.
    @songs = @asArray(json.songs || []).map @instanceFromJson app.songs.Song
    @user = @getJsonUser json.user
    # @updated = json.updated

  # PATTERN(steida): Use only server unique props, because user is going to be
  # saved into localStorage, which is shared across browser tabs/windows.
  getJsonUser: (user) ->
    return null if !user
    displayName: user.displayName
    id: user.id
    provider: user.provider
    thirdPartyUserData: user.thirdPartyUserData
    uid: user.uid

  ###*
    @param {Object} authUser
    @param {Object} serverUserStoreJson
  ###
  updateFromServer: (authUser, serverUserStoreJson) ->
    @user = authUser
    localUserStoreJson = @toJson()
    @mergeSongs localUserStoreJson, serverUserStoreJson
    @fromJson localUserStoreJson
    if goog.DEBUG
      console.log 'store serverNotify'
    @serverNotify()

  ###*
    @param {Object} localUserStoreJson
    @param {Object} serverUserStoreJson
  ###
  mergeSongs: (localUserStoreJson, serverUserStoreJson) ->
    # serverUserStoreJson can be null for new user.
    return if !serverUserStoreJson
    serverSongs = serverUserStoreJson.songs
    return if !serverSongs
    for serverSongId, serverSong of serverSongs
      localSong = localUserStoreJson.songs[serverSongId]
      if !localSong
        localUserStoreJson.songs[serverSongId] = serverSong
        continue
      @mergeSong localSong, serverSong
    return

  ###*
    @param {Object} localSong
    @param {Object} serverSong
  ###
  mergeSong: (localSong, serverSong) ->
    localSong.name = serverSong.name
    localSong.artist = serverSong.artist
    localSong.lyrics = serverSong.lyrics

  ###*
    PATTERN(steida): Logout deletes all user data in memory and in local storage,
    but only if user was logged. We don't want to delete localStorage on page
    reload for not yet logged user.
    @param {boolean} userWasLoggedOnce
  ###
  onLogout: (userWasLoggedOnce) ->
    if userWasLoggedOnce
      @setEmpty()
    else
      @user = null
    @notify()
