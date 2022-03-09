package com.documentscanner;

import android.app.Activity;
import android.graphics.Bitmap;
import android.util.Base64;

import com.documentscanner.views.MainView;
import com.documentscanner.views.OpenNoteCameraView;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;


import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.io.ByteArrayOutputStream;

import javax.annotation.Nullable;


public class DocumentScannerViewManager extends ViewGroupManager<MainView> {

    public static final String REACT_CLASS = "RNPdfScanner";
    private MainView view = null;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected MainView createViewInstance(final ThemedReactContext reactContext) {
        // OpenNoteCameraView view = new OpenNoteCameraView(reactContext, -1,
        // reactContext.getCurrentActivity());
        MainView.createInstance(reactContext, (Activity) reactContext.getBaseContext());

        view = MainView.getInstance();
        view.setOnProcessingListener(new OpenNoteCameraView.OnProcessingListener() {
            @Override
            public void onProcessingChange(WritableMap data) {
                dispatchEvent(reactContext, "onProcessingChange", data);
            }
        });

        view.setOnScannerListener(new OpenNoteCameraView.OnScannerListener() {
            @Override
            public void onPictureTaken(WritableMap data) {
                dispatchEvent(reactContext, "onPictureTaken", data);
            }
        });

        return view;
    }

    private void dispatchEvent(ReactContext reactContext, String eventName, @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
    }

    @ReactProp(name = "documentAnimation", defaultBoolean = false)
    public void setDocumentAnimation(MainView view, boolean animate) {
        view.setDocumentAnimation(animate);
    }

    @ReactProp(name = "overlayColor")
    public void setOverlayColor(MainView view, String rgbaColor) {
        view.setOverlayColor(rgbaColor);
    }

    @ReactProp(name = "detectionCountBeforeCapture", defaultInt = 15)
    public void setDetectionCountBeforeCapture(MainView view, int numberOfRectangles) {
        view.setDetectionCountBeforeCapture(numberOfRectangles);
    }

    @ReactProp(name = "enableTorch", defaultBoolean = false)
    public void setEnableTorch(MainView view, Boolean enable) {
        view.setEnableTorch(enable);
    }

    @ReactProp(name = "useBase64", defaultBoolean = false)
    public void setUseBase64(MainView view, Boolean useBase64) {
        view.setUseBase64(useBase64);
    }

    @ReactProp(name = "manualOnly", defaultBoolean = false)
    public void setManualOnly(MainView view, Boolean manualOnly) {
        view.setManualOnly(manualOnly);
    }

    @ReactProp(name = "brightness", defaultDouble = 10)
    public void setBrightness(MainView view, double brightness) {
        view.setBrightness(brightness);
    }

    @ReactProp(name = "contrast", defaultDouble = 1)
    public void setContrast(MainView view, double contrast) {
        view.setContrast(contrast);
    }

    @ReactProp(name = "noGrayScale", defaultBoolean = false)
    public void setRemoveGrayScale(MainView view, boolean bw) {
        view.setRemoveGrayScale(bw);
    }




    @ReactMethod
    public void crop(ReadableMap points, String imageUri, Callback callback) {

        Point tl = new Point(points.getMap("topLeft").getDouble("x"), points.getMap("topLeft").getDouble("y"));
        Point tr = new Point(points.getMap("topRight").getDouble("x"), points.getMap("topRight").getDouble("y"));
        Point bl = new Point(points.getMap("bottomLeft").getDouble("x"), points.getMap("bottomLeft").getDouble("y"));
        Point br = new Point(points.getMap("bottomRight").getDouble("x"), points.getMap("bottomRight").getDouble("y"));

        Mat src = Imgcodecs.imread(imageUri.replace("file://", ""), Imgproc.COLOR_BGR2RGB);
        Imgproc.cvtColor(src, src, Imgproc.COLOR_BGR2RGB);

        boolean ratioAlreadyApplied = tr.x * (src.size().width / 500) < src.size().width;
        double ratio = ratioAlreadyApplied ? src.size().width / 500 : 1;

        double widthA = Math.sqrt(Math.pow(br.x - bl.x, 2) + Math.pow(br.y - bl.y, 2));
        double widthB = Math.sqrt(Math.pow(tr.x - tl.x, 2) + Math.pow(tr.y - tl.y, 2));

        double dw = Math.max(widthA, widthB) * ratio;
        int maxWidth = Double.valueOf(dw).intValue();

        double heightA = Math.sqrt(Math.pow(tr.x - br.x, 2) + Math.pow(tr.y - br.y, 2));
        double heightB = Math.sqrt(Math.pow(tl.x - bl.x, 2) + Math.pow(tl.y - bl.y, 2));

        double dh = Math.max(heightA, heightB) * ratio;
        int maxHeight = Double.valueOf(dh).intValue();

        Mat doc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

        Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
        Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

        src_mat.put(0, 0, tl.x * ratio, tl.y * ratio, tr.x * ratio, tr.y * ratio, br.x * ratio, br.y * ratio, bl.x * ratio,
                bl.y * ratio);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);

        Imgproc.warpPerspective(src, doc, m, doc.size());

        Bitmap bitmap = Bitmap.createBitmap(doc.cols(), doc.rows(), Bitmap.Config.ARGB_8888);
        Utils.matToBitmap(doc, bitmap);

        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 70, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();

        WritableMap map = Arguments.createMap();
        map.putString("image", Base64.encodeToString(byteArray, Base64.DEFAULT));
        callback.invoke(null, map);

        m.release();
    }
}
