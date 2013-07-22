module = angular.module('alchemy.controllers', ['http-auth-interceptor', 'ngCookies'])

class ChatRoomController
        constructor: (@$scope, @jabber) ->
                @$scope.username = ""
                @$scope.password = ""
                @$scope.nickname = "alchemist"

                @$scope.status = 0

                @$scope.room_name = "#test@conference.im.linux62.org"
                @$scope.room_topic = null
                @$scope.room = null

                @$scope.messages = []

                @$scope.occupants = {}

                @$scope.form =
                        message: null

                @$scope.connect = this.connect
                @$scope.sendMessage = this.sendMessage

                # XXX Shouldn't be here
                $(window).unload(=>
                        @jabber.connection.disconnect()
                )

        getVcard: (jid) =>
                return @$scope.occupants[jid].vcard

        onRosterList: (occupant_list) =>
                @$scope.occupants = {}
                console.debug("Received occupant list")

                @$scope.$apply( =>
                        for occupant_name of occupant_list
                                occupant = occupant_list[occupant_name]
                                console.debug(occupant)
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
                                console.debug("Jabber connecting...")
                        when Strophe.Status.CONNECTED
                                console.debug("Jabber connected.")
                                @jabber.room_join(@$scope.room_name, @$scope.nickname, this.onMessageReceived, this.onRosterList)
                                @$scope.room = @jabber.connection.muc.rooms[@$scope.room_name]

                return true

        connect: =>
                @jabber.connect(@$scope.username, @$scope.password, this.onConnect)

module.controller("ChatRoomController", ['$scope', 'jabber', ChatRoomController])