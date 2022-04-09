import DocumentScanner from "./DocumentScanner";
import DocumentCropper from "./DocumentCropper";
import {NativeModules} from "react-native";


/**
 * 检测文档边界
 * @param {string} imageUri 
 * @param {*} callback 
 */
function detectDocument(imageUri,callback){
    NativeModules.RNPdfScannerManager.detectDocument(imageUri,callback);
}

/**
 * 旋转图片(每次顺时针旋转90度)
 * @param {*} uri 
 * @param {*} angle 
 * @param {*} success 
 * @param {*} fail 
 */
function rotateImage(uri,angle,callback){
    NativeModules.RNPdfScannerManager.rotateImage(uri,angle,callback);
}

/**
 * 导出文档扫描器和图片裁剪器
 */
export {DocumentScanner,DocumentCropper,detectDocument,rotateImage}