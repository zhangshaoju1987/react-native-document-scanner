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
 * 可以是file开头的文件路径或者是纯base64的图片内容
 * @param {*} uri 
 * @param {*} callback 
 */
function rotate90(imageUri,callback){
    NativeModules.RNPdfScannerManager.rotateImage(imageUri,callback);
}

/**
 * 导出文档扫描器和图片裁剪器
 */
export {DocumentScanner,DocumentCropper,detectDocument,rotate90}