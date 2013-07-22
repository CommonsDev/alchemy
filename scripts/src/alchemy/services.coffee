services = angular.module("alchemy.services", [])

class JabberService
        constructor: (@$rootScope) ->
                @connection = new Strophe.Connection("http://bosh.metajack.im:5280/xmpp-httpbind")

                @connection.rawInput = (data) ->
                        console.debug(data)

                @connection.rawOutput = (data) ->
                        # console.debug(data)


        connect: (username, password, callback) =>
                @connection.connect(username, password, callback)

        room_join: (name, nickname, msg_cb, roster_cb) =>
                @connection.muc.join(name, nickname, msg_cb, null, roster_cb) # XXX

        room_message: (room, msg) =>
                @connection.muc.groupchat(room, msg) # XXX


services.service("jabber", [ "$rootScope", JabberService])