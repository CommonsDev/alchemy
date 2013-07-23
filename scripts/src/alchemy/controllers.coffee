module = angular.module('alchemy.controllers', ['http-auth-interceptor', 'LocalStorageModule'])

class AlchemyController
        constructor: (@$scope) ->
                @$scope.room_names = ["#test@conference.im.linux62.org", "#yeah@conference.im.linux62.org"]

class ChatRoomController
        constructor: (@$scope, @localStorageService, @jabber) ->
                @$scope.nickname = "alchemist2"

                @$scope.status = 0

                @$scope.room_topic = null
                @$scope.room = null

                @$scope.messages = []

                @$scope.occupants = {}

                @$scope.form =
                        message: null
                        username: ""
                        password: ""


                @$scope.connect = this.connect
                @$scope.sendMessage = this.sendMessage

                # XXX Shouldn't be here
                $(window).bind('beforeunload', (e) =>
                        # Save ids in the localstorage to restore connection later if needed
                        if @$scope.status in [Strophe.Status.CONNECTED, Strophe.Status.ATTACHED]
                                #@localStorageService.add('jid', @jabber.connection.jid)
                                #@localStorageService.add('sid', @jabber.connection.sid)
                                #@localStorageService.add('rid', @jabber.connection.rid)

                                # Quit room
                                # @jabber.room_leave(@$scope.room.name, @$scope.nickname)

                                @jabber.connection.disconnect()

                        return "You are to be disconnected."

                )

        getVcard: (jid) =>
                return @$scope.occupants[jid].vcard

        onRosterList: (occupant_list) =>
                @$scope.occupants = {}
                console.debug("Received occupant list")

                @$scope.$apply( =>
                        for occupant_name of occupant_list
                                occupant = occupant_list[occupant_name]
                                # console.debug(occupant)
                                @$scope.occupants[occupant.jid] = {
                                        occupant: occupant
                                        vcard: null
                                }
                )


                for occupant_name of occupant_list
                        occupant = occupant_list[occupant_name]
                        @jabber.connection.vcard.get((stanza, vcard) =>
                                @$scope.$apply(=>
                                        vcard = @$scope.occupants[occupant.jid].vcard = {}
                                        photo = $(stanza).find("PHOTO")[0]
                                        vcard.photo_type = $(photo).children("TYPE").text()
                                        vcard.photo_data = $(photo).children("BINVAL").text()
                                )
                        ,
                        Strophe.getBareJidFromJid(occupant.jid)
                        )



        sendMessage: =>
                """
                On form submit, send message to room
                """
                @jabber.room_message(@$scope.room.name, @$scope.form.message)
                @$scope.form.message = ""

        onMessageReceived: (stanza, room) =>
                """
                When receiving a message from the chatroom
                """
                from = stanza.getAttribute('from')
                to = stanza.getAttribute('to')

                # Set topic?
                query = stanza.getElementsByTagName("subject")
                if query.length > 0
                        subject = Strophe.getText(query[0])
                        @$scope.$apply(=>
                                @$scope.room_topic = subject
                        )
                        return true

                # Chat msg?
                body = stanza.getElementsByTagName("body")[0]
                message = Strophe.getText(body)
                if message
                        @$scope.$apply(=>
                                @$scope.messages.push(
                                        from: Strophe.getResourceFromJid(from)
                                        text: message
                                )
                        )
                        return true

                return true


        onConnect: (status) =>
                @$scope.status = status

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
                                console.debug(@jabber.connection.muc.rooms[@$scope.room_name])
                                @jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                @$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]
                                return true

                        when Strophe.Status.CONNECTED
                                console.debug("#{status}: Jabber connected.")
                                @jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                @$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]
                                return true

                        when Strophe.Status.DISCONNECTING
                                console.debug("#{status}: Disconnecting...")
                                return true

                        when Strophe.Status.DISCONNECTED
                                console.debug("#{status}: Disconnected.")
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
                        @jabber.connection_restore(jid, sid, rid, this.onConnect)
                else
                        @jabber.connect(@$scope.form.username, @$scope.form.password, this.onConnect)

module.controller("ChatRoomController", ['$scope', 'localStorageService', 'jabber', ChatRoomController])
module.controller("AlchemyController", ['$scope', AlchemyController])