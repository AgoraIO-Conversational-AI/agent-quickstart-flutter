(function () {
  function toMessage(error) {
    if (!error) {
      return 'Agora RTM web bridge error';
    }
    if (typeof error === 'string') {
      return error;
    }
    if (error.message) {
      return error.message;
    }
    return String(error);
  }

  function createClient(appId, userId, config) {
    if (!window.AgoraRTM || !window.AgoraRTM.RTM) {
      throw new Error('AgoraRTM web SDK is not loaded.');
    }

    var client = new window.AgoraRTM.RTM(appId, userId, config || {});

    return {
      login: function (token, onSuccess, onError) {
        client.login({ token: token }).then(onSuccess).catch(function (error) {
          onError(toMessage(error));
        });
      },
      subscribe: function (channelName, withMessage, withPresence, onSuccess, onError) {
        client
          .subscribe(channelName, {
            withMessage: withMessage,
            withPresence: withPresence,
          })
          .then(onSuccess)
          .catch(function (error) {
            onError(toMessage(error));
          });
      },
      renewToken: function (token, onSuccess, onError) {
        client.renewToken(token).then(onSuccess).catch(function (error) {
          onError(toMessage(error));
        });
      },
      unsubscribe: function (channelName, onSuccess, onError) {
        client.unsubscribe(channelName).then(onSuccess).catch(function (error) {
          onError(toMessage(error));
        });
      },
      logout: function (onSuccess, onError) {
        client.logout().then(onSuccess).catch(function (error) {
          onError(toMessage(error));
        });
      },
      release: function (onSuccess, onError) {
        Promise.resolve(client.release ? client.release() : undefined)
          .then(onSuccess)
          .catch(function (error) {
            onError(toMessage(error));
          });
      },
      addMessageListener: function (handler) {
        client.addEventListener('message', handler);
      },
      addPresenceListener: function (handler) {
        client.addEventListener('presence', handler);
      },
      addStatusListener: function (handler) {
        client.addEventListener('status', handler);
      },
    };
  }

  window.flutterAgoraRtm = {
    createClient: createClient,
  };
})();
