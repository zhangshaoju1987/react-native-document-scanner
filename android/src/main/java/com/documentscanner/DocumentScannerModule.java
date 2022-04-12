package com.documentscanner;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Environment;
import android.util.Base64;
import android.util.Log;
import com.documentscanner.views.MainView;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.opencv.android.Utils;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.Date;
import java.util.UUID;


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
    @ReactMethod
    public void stop(){
        MainView view = MainView.getInstance();
        view.stop();
    }

    /**
     * 单独检测文档边界
     * @param imageUri
     * @param callback
     */
    @ReactMethod
    public void detectDocument(String imageUri, Callback callback) {

        try{
            Mat picture = Imgcodecs.imread(imageUri.replace("file://", ""), Imgproc.COLOR_BGR2RGB);
            int width = picture.width();
            int height = picture.height();
            Log.i("detectDocument","原始图片尺寸:width="+picture.width()+"height="+picture.height());
            Mat img = picture.clone();
            picture.release();// 及时释放
            WritableMap rectangleCoordinates = com.documentscanner.Utils.detectDocumentEdgeFromImage(img);
            img.release();// 及时释放
            WritableMap size = new WritableNativeMap();
            size.putDouble("width",  width);
            size.putDouble("height", height);

            WritableMap documentInfo = new WritableNativeMap();
            documentInfo.putMap("rectangleCoordinates",rectangleCoordinates);
            documentInfo.putMap("size",size);
            documentInfo.putBoolean("success",true);
            callback.invoke(documentInfo);
        }catch (Exception e){
            e.printStackTrace();
            WritableMap err = new WritableNativeMap();
            err.putString("message",e.getMessage());
            err.putBoolean("success",false);
            callback.invoke(err);
        }
    }

    /**
     * 按边界进行裁剪
     * @param points
     * @param imageUri
     * @param callback
     */
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

        src_mat.put(0, 0, tl.x * ratio, tl.y * ratio, tr.x * ratio, tr.y * ratio, br.x * ratio, br.y * ratio, bl.x * ratio, bl.y * ratio);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);

        Imgproc.warpPerspective(src, doc, m, doc.size());
        Imgproc.cvtColor(doc, doc, Imgproc.COLOR_BGR2RGB);

        String folderName = "documents";
        File folder = new File(Environment.getExternalStorageDirectory().toString() + "/" + folderName);
        if (!folder.exists()) {
            folder.mkdirs();
        }
        String originalFile = Environment.getExternalStorageDirectory().toString() + "/" + folderName + "/document0-" + new Date().getTime() + ".jpeg";
        Imgcodecs.imwrite(originalFile,doc);
        WritableMap map = Arguments.createMap();
        map.putString("image", "file://"+originalFile);

        callback.invoke(map);
        m.release();
        src_mat.release();
        dst_mat.release();
        src.release();
        doc.release();
    }

    /**
     * 按边界进行裁剪
     * @param points
     * @param imageUri
     * @param callback
     */
    @ReactMethod
    public void cropImage(ReadableMap points, String imageUri, Callback callback) {

        Point tl = new Point(points.getMap("topLeft").getDouble("x"), points.getMap("topLeft").getDouble("y"));
        Point tr = new Point(points.getMap("topRight").getDouble("x"), points.getMap("topRight").getDouble("y"));
        Point bl = new Point(points.getMap("bottomLeft").getDouble("x"), points.getMap("bottomLeft").getDouble("y"));
        Point br = new Point(points.getMap("bottomRight").getDouble("x"), points.getMap("bottomRight").getDouble("y"));

        Mat src = Imgcodecs.imread(imageUri.replace("file://", ""), Imgproc.COLOR_BGR2RGB);
        Imgproc.cvtColor(src, src, Imgproc.COLOR_BGR2RGB);

        double ratio = 1.0;
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

        src_mat.put(0, 0, tl.x * ratio, tl.y * ratio, tr.x * ratio, tr.y * ratio, br.x * ratio, br.y * ratio, bl.x * ratio, bl.y * ratio);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);
        Imgproc.warpPerspective(src, doc, m, doc.size());
        Imgproc.cvtColor(doc, doc, Imgproc.COLOR_BGR2RGB);

        String folderName = "documents";
        File folder = new File(Environment.getExternalStorageDirectory().toString() + "/" + folderName);
        if (!folder.exists()) {
            folder.mkdirs();
        }
        String originalFile = Environment.getExternalStorageDirectory().toString() + "/" + folderName + "/document1-" + new Date().getTime() + ".jpeg";
        Imgcodecs.imwrite(originalFile,doc);
        WritableMap map = Arguments.createMap();
        map.putString("image", "file://"+originalFile);
        callback.invoke(map);

        m.release();
        src_mat.release();
        dst_mat.release();
        src.release();
        doc.release();
    }

    /**
     * Rotate an image. If all goes well, the success callback will be called with the file:// URI of
     * the new image as the only argument. This is a temporary file - consider using
     * CameraRollManager.saveImageWithTag to save it in the gallery.
     *
     * @param base64Img the MediaStore URI of the image to rotate
     * @param callback callback to be invoked when the image has been rotated; the only argument that
     *        is passed to this callback is the file:// URI of the new image
     */
    @ReactMethod
    public void rotateImage(
            String base64Img,
            final Callback callback) {

        Mat src = new Mat();
        if(base64Img.startsWith("file://")){
            src = Imgcodecs.imread(base64Img.replace("file://", ""), Imgproc.COLOR_BGR2RGB);
        }else{
            byte [] content = Base64.decode(base64Img,Base64.DEFAULT);
            Bitmap bitmap = BitmapFactory.decodeByteArray(content,0,content.length);
            Utils.bitmapToMat(bitmap,src);
        }
        
        Mat tmp = new Mat();
        Core.transpose(src,tmp);    // 转置
        Mat result = new Mat();
        Core.flip(tmp,result,1);    // 翻转

        String folderName = "documents";
        File folder = new File(Environment.getExternalStorageDirectory().toString() + "/" + folderName);
        if (!folder.exists()) {
            folder.mkdirs();
        }
        String originalFile = Environment.getExternalStorageDirectory().toString() + "/" + folderName + "/rotate-" + new Date().getTime() + ".jpeg";
        Imgcodecs.imwrite(originalFile, result);

        WritableMap map = Arguments.createMap();
        map.putString("image", "file://"+originalFile);

        callback.invoke(map);
        src.release();
        tmp.release();
        result.release();
    }

    @ReactMethod
    public void scaleImage(
            String imageUri,
            float scale,
            final Callback callback) {

        String folderName = "documents";
        File folder = new File(Environment.getExternalStorageDirectory().toString() + "/" + folderName);
        if (!folder.exists()) {
            folder.mkdirs();
        }
        String smallFile = Environment.getExternalStorageDirectory().toString() + "/" + folderName + "/scaled_image-" + new Date().getTime() + ".jpeg";
        Mat src = Imgcodecs.imread(imageUri.replace("file://", ""), Imgproc.COLOR_BGR2RGB);
        Mat small = com.documentscanner.Utils.scale(src,scale);
        Imgcodecs.imwrite(smallFile, small);
        // 返回结果
        WritableMap map = Arguments.createMap();
        map.putString("image", "file://"+smallFile);
        callback.invoke(map);
        // 释放资源
        src.release();
        small.release();
    }
}
