module = angular.module('alchemy.controllers', ['http-auth-interceptor', 'LocalStorageModule'])

class ChatRoomController
        constructor: (@$scope, @localStorageService, @jabber) ->
                @$scope.nickname = "alchemist2"

                @$scope.status = 0

                @$scope.room_name = "#test@conference.im.linux62.org"
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

                console.debug("got msg...")
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
                        # $(".oembed").oembed(message, {maxWidth: '300px', maxHeight: '150px'})
                        return true

                return true


        onConnect: (status) =>
                @$scope.status = status

                switch status
                        when Strophe.Status.CONNECTING
                                console.debug("Jabber connecting...")
                                return true

                        when Strophe.Status.ATTACHED
                                console.debug("Jabber BOSH attached.")
                                console.debug(@jabber.connection.muc.rooms[@$scope.room_name])
                                @jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                @$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]
                                return true

                        when Strophe.Status.CONNECTED
                                console.debug("Jabber connected.")
                                @jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                @$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]
                                return true

                        when Strophe.Status.ERROR
                                console.debug("ERROR!")

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