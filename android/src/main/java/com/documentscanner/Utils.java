package com.documentscanner;

import android.util.Log;

import com.documentscanner.helpers.Quadrilateral;
import com.documentscanner.helpers.ScannedDocument;

import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;

public class Utils {

    /**
     * 检测文档边界
     * @param inputRgba
     */
    public static ScannedDocument detectDocumentFromImage(Mat inputRgba){

        ArrayList<MatOfPoint> contours = findContours(inputRgba);
        ScannedDocument sd = new ScannedDocument(inputRgba);
        sd.originalSize = inputRgba.size();
        Quadrilateral quad = getQuadrilateral(contours, sd.originalSize);

        sd.heightWithRatio = Double.valueOf(sd.originalSize.width).intValue();
        sd.widthWithRatio = Double.valueOf(sd.originalSize.height).intValue();
        Log.i("detectDocumentFromImage","缩放图片尺寸"+sd.widthWithRatio+""+sd.heightWithRatio);
        sd.originalPoints = new Point[4];
        sd.originalPoints[0] = quad.points[0]; // Topleft
        sd.originalPoints[1] = quad.points[1]; // TopRight
        sd.originalPoints[2] = quad.points[2]; // BottomRight
        sd.originalPoints[3] = quad.points[3]; // BottomLeft
        return sd;
    }

    /**
     * 提取四边形轮廓
     * @param contours  原始图片上的轮廓列表
     * @param srcSize   原始图片尺寸
     * @return
     */
    private static Quadrilateral getQuadrilateral(ArrayList<MatOfPoint> contours, Size srcSize) {

        int height = Double.valueOf(srcSize.height).intValue();
        int width = Double.valueOf(srcSize.width).intValue();
        Size size = new Size(width, height);

        Log.i("COUCOU", "Size----->" + size);
        for (MatOfPoint c : contours) {
            MatOfPoint2f c2f = new MatOfPoint2f(c.toArray());
            double peri = Imgproc.arcLength(c2f, true);// 计算弧度
            MatOfPoint2f approx = new MatOfPoint2f();
            Imgproc.approxPolyDP(c2f, approx, 0.02 * peri, true);// 通过轮廓近似获取角点
            Point[] points = approx.toArray();
            Point[] foundPoints = fetchPoints(points);

            if (insideArea(foundPoints, size)) {
                return new Quadrilateral(c, foundPoints);
            }
        }

        return null;
    }

    /**
     * 获取四边形的4个点(基于四边形规律进行优选)
     * @param src
     * @return
     */
    private static Point[] fetchPoints(Point[] src) {

        ArrayList<Point> srcPoints = new ArrayList<>(Arrays.asList(src));
        Point[] result = { null, null, null, null };

        /**
         * 获取右下角的点
         */
        Comparator<Point> sumComparator = new Comparator<Point>() {
            @Override
            public int compare(Point lhs, Point rhs) {
                return Double.valueOf(lhs.y + lhs.x).compareTo(rhs.y + rhs.x);
            }
        };

        Comparator<Point> diffComparator = new Comparator<Point>() {

            @Override
            public int compare(Point lhs, Point rhs) {
                return Double.valueOf(lhs.y - lhs.x).compareTo(rhs.y - rhs.x);
            }
        };
        // top-left corner =  和值最小
        result[0] = Collections.min(srcPoints, sumComparator);

        // top-right corner = 差值最小
        result[1] = Collections.min(srcPoints, diffComparator);

        // bottom-right corner = 和值最大
        result[2] = Collections.max(srcPoints, sumComparator);

        // bottom-left corner = 差值最大
        result[3] = Collections.max(srcPoints, diffComparator);

        return result;
    }
    private static boolean insideArea(Point[] rp, Size size) {

        int width = Double.valueOf(size.width).intValue();
        int minimumSize = width / 10;

        boolean isANormalShape = rp[0].x != rp[1].x && rp[1].y != rp[0].y && rp[2].y != rp[3].y && rp[3].x != rp[2].x;
        boolean isBigEnough = ((rp[1].x - rp[0].x >= minimumSize) && (rp[2].x - rp[3].x >= minimumSize)
                && (rp[3].y - rp[0].y >= minimumSize) && (rp[2].y - rp[1].y >= minimumSize));

        double leftOffset = rp[0].x - rp[3].x;
        double rightOffset = rp[1].x - rp[2].x;
        double bottomOffset = rp[0].y - rp[1].y;
        double topOffset = rp[2].y - rp[3].y;

        boolean isAnActualRectangle = ((leftOffset <= minimumSize && leftOffset >= -minimumSize)
                && (rightOffset <= minimumSize && rightOffset >= -minimumSize)
                && (bottomOffset <= minimumSize && bottomOffset >= -minimumSize)
                && (topOffset <= minimumSize && topOffset >= -minimumSize));

        return isANormalShape && isAnActualRectangle && isBigEnough;
    }

    /**
     * 查找文档离所有的轮廓并且按轮廓面积降序排列
     * @param src
     * @return
     */
    private static ArrayList<MatOfPoint> findContours(Mat src) {

        Mat grayImage = null;
        Mat cannedImage = null;
        Mat resizedImage = null;

        int height = Double.valueOf(src.size().height).intValue();
        int width = Double.valueOf(src.size().width).intValue();
        Size size = new Size(width, height);

        resizedImage = new Mat(size, CvType.CV_8UC4);
        grayImage = new Mat(size, CvType.CV_8UC4);
        cannedImage = new Mat(size, CvType.CV_8UC1);

        Imgproc.resize(src, resizedImage, size);// 统一图片大小
        Imgproc.cvtColor(resizedImage, grayImage, Imgproc.COLOR_RGBA2GRAY, 4);// 图片灰度化
        Imgproc.GaussianBlur(grayImage, grayImage, new Size(5, 5), 0);// 去噪点
        Imgproc.Canny(grayImage, cannedImage, 80, 100, 3, false);// 边缘检测

        ArrayList<MatOfPoint> contours = new ArrayList<MatOfPoint>();
        Mat hierarchy = new Mat();
        // 基于边界查找可能存在的轮廓
        Imgproc.findContours(cannedImage, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE);
        hierarchy.release();
        Collections.sort(contours, new Comparator<MatOfPoint>() {

            @Override
            public int compare(MatOfPoint lhs, MatOfPoint rhs) {
                // 按轮廓面积降序排列
                return Double.valueOf(Imgproc.contourArea(rhs)).compareTo(Imgproc.contourArea(lhs));
            }
        });
        // 释放资源
        resizedImage.release();
        grayImage.release();
        cannedImage.release();
        return contours;
    }
}
