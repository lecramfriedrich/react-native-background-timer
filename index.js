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
				if (!this.callbacks[id].interval) {
					console.log('execute', Date.now(), this.callbacks[id].timestamp, Date.now() - this.callbacks[id].timestamp);
					delete this.callbacks[id];
				}
				else {
					RNBackgroundTimer.setTimeout(id, this.callbacks[id].timeout);
				}
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

	runBackgroundTimer = (callback, delay) => {
		const EventEmitter = Platform.select({
			ios: () => NativeAppEventEmitter,
			android: () => DeviceEventEmitter,
		})();
		this.start(0);
		this.backgroundListener = EventEmitter.addListener('backgroundTimer', () => {
			this.backgroundListener.remove();
			this.backgroundClockMethod(callback, delay)
		});
	};

	backgroundClockMethod(callback, delay) {
		this.backgroundTimer = setTimeout(() => {
			callback();
			this.backgroundClockMethod(callback, delay);
		},
			delay);
	}

	stopBackgroundTimer = () => {
		this.stop();
		clearTimeout(this.backgroundTimer);
	};

	// New API, allowing for multiple timers
	setTimeout(callback, timestamp) {
		const timeoutId = ++this.uniqueId;
		this.callbacks[timeoutId] = {
			callback: callback,
			interval: false,
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
			//RNBackgroundTimer.clearTimeout(timeoutId);
		}
	}

	setInterval(callback, timeout) {
		const intervalId = ++this.uniqueId;
		this.callbacks[intervalId] = {
			callback: callback,
			interval: true,
			timeout: timeout
		};
		RNBackgroundTimer.setTimeout(intervalId, timeout);
		return intervalId;
	}

	clearInterval(intervalId) {
		if (this.callbacks[intervalId]) {
			delete this.callbacks[intervalId];
			//RNBackgroundTimer.clearTimeout(intervalId);
		}
	}
};

export default new BackgroundTimer();
