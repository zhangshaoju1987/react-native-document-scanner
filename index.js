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
 * 缩放图片
 * @param {String} uri file://开头的uri
 *  @param {Number} uri file://开头的uri
 * @param {Function} callback 
 */
 function scale(imageUri,scale,callback){
    NativeModules.RNPdfScannerManager.scaleImage(imageUri,scale,callback);
}
/**
 * 生成缩率图
 * @param {String} imageUri 
 * @param {Number} scale 
 * @param {Number} quality 
 * @param {Function} callback 
 */
function thumbnail(imageUri,scale=0.25,quality=0.8,callback){
    NativeModules.RNPdfScannerManager.thumbnail(imageUri,scale,quality,callback);

}

/**
 * 导出文档扫描器和图片裁剪器
 */
export {DocumentScanner,DocumentCropper,detectDocument,rotate90,scale,thumbnail}