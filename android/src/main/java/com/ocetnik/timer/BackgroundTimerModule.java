package com.ocetnik.timer;

import android.os.Handler;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import android.os.PowerManager;
import android.os.PowerManager.WakeLock;

import java.lang.Runnable;

public class BackgroundTimerModule extends ReactContextBaseJavaModule {

    private Handler handler;
    private ReactContext reactContext;
    private Runnable runnable;
	private WakeLock mWakeLock;

    public BackgroundTimerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
		this.mWakeLock = ((PowerManager) getReactApplicationContext().getSystemService("power")).newWakeLock(1, "TimerServiceLock");
    }

    @Override
    public String getName() {
        return "RNBackgroundTimer";
    }

    @ReactMethod
    public void start() {
		this.mWakeLock.acquire();
        handler = new Handler();
        runnable = new Runnable() {
            @Override
            public void run() {
                sendEvent(reactContext, "backgroundTimer");
            }
        };

        handler.post(runnable);
    }

    @ReactMethod
    public void stop() {
		if (this.mWakeLock.isHeld()) {
            this.mWakeLock.release();
        }
        // avoid null pointer exceptio when stop is called without start
        if (handler != null) handler.removeCallbacks(runnable);
    }

    private void sendEvent(ReactContext reactContext, String eventName) {
        reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, null);
    }

    @ReactMethod
    public void setTimeout(final int id, final int timeout) {
        Handler handler = new Handler();
        handler.postDelayed(new Runnable(){
            @Override
            public void run(){
                if (getReactApplicationContext().hasActiveCatalystInstance()) {
                    getReactApplicationContext()
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("backgroundTimer.timeout", id);
                }
           }
        }, timeout);
    }
}