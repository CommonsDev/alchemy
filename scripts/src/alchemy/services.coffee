services = angular.module("alchemy.services", ['LocalStorageModule'])

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


services.service("jabber", [ "$rootScope", "localStorageService", JabberService])