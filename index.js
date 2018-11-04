import {
	NativeModules,
	NativeEventEmitter,
	DeviceEventEmitter,
	NativeAppEventEmitter,
	Platform,
} from 'react-native';

const { RNBackgroundTimer } = NativeModules;
const Emitter = new NativeEventEmitter(RNBackgroundTimer);

class BackgroundTimer {

	constructor() {
		this.uniqueId = 0;
		this.callbacks = {};

		Emitter.addListener('backgroundTimer.timeout', (id) => {
			if (this.callbacks[id]) {
				const callback = this.callbacks[id].callback;
				delete this.callbacks[id];
				callback();
			}
		});
	}

	// Original API
	start() {
		return RNBackgroundTimer.start();
	}

	stop() {
		return RNBackgroundTimer.stop();
	}

	// New API, allowing for multiple timers
	setTimeout(callback, timestamp) {
		const timeoutId = ++this.uniqueId;
		this.callbacks[timeoutId] = {
			callback: callback,
			timestamp: timestamp
		};
		const time = timestamp - Date.now();
		if (time > 0) {
			RNBackgroundTimer.setTimeout(timeoutId, time);
		}
		return timeoutId;
	}

	clearTimeout(timeoutId) {
		if (this.callbacks[timeoutId]) {
			delete this.callbacks[timeoutId];
		}
	}
};

export default new BackgroundTimer();
