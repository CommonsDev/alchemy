services = angular.module("alchemy.services", ['LocalStorageModule', 'ngResource'])

class JabberService
        constructor: (@$rootScope, @localStorageService) ->
                @connection = new Strophe.Connection("http://carpe.local:5280/http-bind/")

                @connection.rawInput = (data) ->
                        # console.debug(data)

                @connection.rawOutput = (data) ->
                        # console.debug(data)

                @status = 0

                @$rootScope.jabber_login =
                        username: "bob@carpe.local"
                        password: "plop"


                # XXX Shouldn't be here
                $(window).bind('beforeunload', (e) =>
                        # Save ids in the localstorage to restore connection later if needed
                        if @status in [Strophe.Status.CONNECTED, Strophe.Status.ATTACHED]
                                #@localStorageService.add('jid', @jabber.connection.jid)
                                #@localStorageService.add('sid', @jabber.connection.sid)
                                #@localStorageService.add('rid', @jabber.connection.rid)

                                # Quit room
                                # @jabber.room_leave(@$scope.room.name, @$scope.nickname)

                                @connection.disconnect()

                        return "You are to be disconnected."

                )




        onConnect: (status) =>
                """
                Callback for server connection
                """
                @status = status

                switch status
                        when Strophe.Status.CONNECTING
                                console.debug("#{status}: Jabber connecting...")
                                return true

                        when Strophe.Status.CONNFAIL
                                console.debug("#{status}: Connection failed")
                                return true

                        when Strophe.Status.AUTHENTICATING
                                console.debug("#{status}: Authenticating...")
                                return true

                        when Strophe.Status.AUTHFAIL
                                console.debug("#{status}: Auth failed")
                                return true

                        when Strophe.Status.ATTACHED
                                console.debug("#{status}: Jabber BOSH attached.")
                                @$rootScope.$broadcast('jabber-attached')
                                #console.debug(@jabber.connection.muc.rooms[@$scope.room_name])
                                #@jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                #@$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]
                                return true

                        when Strophe.Status.CONNECTED
                                console.debug("#{status}: Jabber connected.")
                                @$rootScope.$broadcast('jabber-connected')
                                return true

                        when Strophe.Status.DISCONNECTING
                                console.debug("#{status}: Disconnecting...")
                                @$rootScope.$broadcast('jabber-connecting')
                                return true

                        when Strophe.Status.DISCONNECTED
                                console.debug("#{status}: Disconnected.")
                                @$rootScope.$broadcast('jabber-disconnected')
                                return true

                        when Strophe.Status.ERROR
                                console.debug("ERROR!")
                                return true

                return true


        connect: =>
                # Try to restore connection
                jid = @localStorageService.get('jid')
                sid = @localStorageService.get('sid')
                rid = @localStorageService.get('rid')

                # Empty session
                @localStorageService.clearAll()

                if jid and sid and rid
                        console.debug("Attaching connection... #{jid} #{sid} #{rid}")
                        @connection.attach(jid, sid, rid, callback)
                else
                        @connection.connect(@$rootScope.jabber_login.username, @$rootScope.jabber_login.password, this.onConnect)

        room_join: (name, nickname, msg_cb, presence_cb, roster_cb) =>
                @connection.muc.join(name, nickname, msg_cb, presence_cb, roster_cb, null,
                        maxstanzas: 50
                        ) # XXX

        room_leave: (name, nickname) =>
                @connection.muc.leave(name, nickname)

        room_message: (room, msg) =>
                @connection.muc.groupchat(room, msg) # XXX

class UserMediaService
        """
        Service to get video and audio from user
        """
        constructor: (@$rootScope) ->
                RTC = null
                if navigator.mozGetUserMedia and mozRTCPeerConnection
                        console.log "This appears to be Firefox"
                        ua = navigator.userAgent.split(" ")
                        isnightly = false
                        try
                                ver = ua.pop()
                                build = ua.pop().split("/").pop()
                                if parseFloat(ver.split("/")[1]) > 21.0
                                        isnightly = true
                        catch e
                                console.error "uhm..."

                        if isnightly
                                RTC =
                                        peerconnection: mozRTCPeerConnection
                                        browser: "firefox"
                                        getUserMedia: navigator.mozGetUserMedia.bind(navigator)
                                        attachMediaStream: (element, stream) ->
                                                element[0].mozSrcObject = stream
                                                element[0].play()
                                        pc_constraints: {}

                                MediaStream::getVideoTracks = ->
                                        []

                                MediaStream::getAudioTracks = ->
                                        []

                                window.RTCSessionDescription = mozRTCSessionDescription
                                window.RTCIceCandidate = mozRTCIceCandidate

                else if navigator.webkitGetUserMedia
                        console.log "This appears to be Chrome"
                        RTC =
                                peerconnection: webkitRTCPeerConnection
                                browser: "chrome"
                                getUserMedia: navigator.webkitGetUserMedia.bind(navigator)
                                attachMediaStream: (element, stream) ->
                                        element.attr("src", webkitURL.createObjectURL(stream))
                                pc_constraints:
                                        optional: [ DtlsSrtpKeyAgreement: "true" ]

                        RTC.pc_constraints = {}  unless navigator.userAgent.indexOf("Android") is -1
                        unless webkitMediaStream::getVideoTracks
                                webkitMediaStream::getVideoTracks = ->
                                        @videoTracks
                        unless webkitMediaStream::getAudioTracks
                                webkitMediaStream::getAudioTracks = ->
                                        @audioTracks

                        unless RTC?
                                try
                                        console.log "Browser does not appear to be WebRTC-capable"

                window.RTC = RTC
                window.RTCPeerconnection = RTC.peerconnection

        getUserMediaWithConstraints: (um, resolution, bandwidth, fps, callback) ->
                constraints =
                        audio: false
                        video: false

                constraints.video = true  if $.inArray("video", um) >= 0
                constraints.audio = true  if $.inArray("audio", um) >= 0

                if $.inArray("screen", um) >= 0
                        constraints.video = mandatory:
                                chromeMediaSource: "screen"

                switch resolution
                        when "720", "hd"
                                constraints.video = mandatory:
                                        minWidth: 1280
                                        minHeight: 720
                                        minAspectRatio: 1.77
                        when "360"
                                constraints.video = mandatory:
                                        minWidth: 640
                                        minHeight: 360
                                        minAspectRatio: 1.77
                        when "180"
                                constraints.video = mandatory:
                                        minWidth: 320
                                        minHeight: 180
                                        minAspectRatio: 1.77
                        when "960"
                                constraints.video = mandatory:
                                        minWidth: 960
                                        minHeight: 720
                        when "640", "vga"
                                constraints.video = mandatory:
                                        maxWidth: 640
                                        maxHeight: 480
                        when "320"
                                constraints.video = mandatory:
                                        maxWidth: 320
                                        maxHeight: 240
                        else
                                unless navigator.userAgent.indexOf("Android") is -1
                                        constraints.video = mandatory:
                                                maxWidth: 320
                                                maxHeight: 240
                                                maxFrameRate: 15

                constraints.video.optional = [ bandwidth: bandwidth ]  if bandwidth
                constraints.video.mandatory["minFrameRate"] = fps  if fps
                try
                        RTC.getUserMedia(constraints, ((stream) ->
                                console.log("onUserMediaSuccess")
                                # $(document).trigger "mediaready.jingle", [ stream ]
                                callback(stream)
                        ), (error) ->
                                console.warn("Failed to get access to local media. Error ", error)
                                $(document).trigger "mediafailure.jingle"
                        )
                catch e
                        console.error "GUM failed: ", e
                        $(document).trigger "mediafailure.jingle"


# Models
services.factory("Room", ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}api/alambic/v0/room/?format=json")
])

services.factory("Bucket", ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}bucket/api/v0/bucket/:id?format=json")
])


# Services
services.service("jabber", ["$rootScope", "localStorageService", JabberService])
services.service("usermedia", ["$rootScope", UserMediaService])
