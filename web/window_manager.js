(function (window) {
  'use strict';

  function toHashRoute(route) {
    if (!route.startsWith('/')) {
      route = '/' + route;
    }
    return '/#' + route;
  }

  function openPopup(route, features) {
    return window.open(toHashRoute(route), '_blank', features);
  }

  function withQuery(path, params) {
    var qs = new URLSearchParams(params);
    return path + '?' + qs.toString();
  }

  function getCurrentRoomRouteWithCam(userId) {
    var hash = window.location.hash || '';
    var route = hash.startsWith('#') ? hash.substring(1) : hash;
    if (!route.startsWith('/room')) {
      return withQuery('/chat', { userId: userId, popout: 'cam' });
    }

    var joiner = route.indexOf('?') >= 0 ? '&' : '?';
    return route + joiner + 'focusUserId=' + encodeURIComponent(userId);
  }

  var channel = null;
  try {
    channel = new BroadcastChannel('mixmingle');
  } catch (_) {
    channel = null;
  }

  window.mixmingleWindows = {
    channel: channel,

    openRoom: function (roomId) {
      if (!roomId) return null;
      this.send('room.popoutRequested', { roomId: roomId });
      return openPopup(
        withQuery('/room', { roomId: roomId, popout: '1' }),
        'width=1100,height=800'
      );
    },

    openPrivateChat: function (userId) {
      if (!userId) return null;
      this.send('chat.popoutRequested', { userId: userId });
      return openPopup(
        withQuery('/chat', { userId: userId, popout: '1' }),
        'width=500,height=700'
      );
    },

    openCam: function (userId) {
      if (!userId) return null;
      this.send('room.camPopoutRequested', { userId: userId });
      return openPopup(getCurrentRoomRouteWithCam(userId), 'width=420,height=460');
    },

    send: function (event, data) {
      if (!channel) return;
      channel.postMessage({ event: event, data: data });
    },

    listen: function (callback) {
      if (!channel || typeof callback !== 'function') return;
      channel.onmessage = function (msg) {
        callback(msg.data);
      };
    }
  };
})(window);
