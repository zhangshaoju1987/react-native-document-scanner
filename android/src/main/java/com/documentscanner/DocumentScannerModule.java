package com.documentscanner;

import com.documentscanner.views.MainView;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class DocumentScannerModule extends ReactContextBaseJavaModule{

    public DocumentScannerModule(ReactApplicationContext reactContext){
        super(reactContext);
    }


    @Override
    public String getName() {
        return "RNPdfScannerManager";
    }

    @ReactMethod
    public void capture(){
        MainView view = MainView.getInstance();
        view.capture();
    }
}
