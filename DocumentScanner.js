import React from "react";
import {requireNativeComponent,NativeModules,Platform,PermissionsAndroid,DeviceEventEmitter,View} from "react-native";
import PropTypes from "prop-types";

const RNPdfScanner = requireNativeComponent("RNPdfScanner");

/**
 * 扫描照片,获取文档的边界点
 */
export default class DocumentScanner extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      permissionsAuthorized: Platform.OS === "ios"
    };
  }

  onPermissionsDenied = () => {
    if (this.props.onPermissionsDenied) this.props.onPermissionsDenied();
  };

  componentDidMount() {
    this.getAndroidPermissions();
    if (Platform.OS === "android") {
      const { onPictureTaken, onProcessing } = this.props;
      this.offOnPictureTaken = DeviceEventEmitter.addListener("onPictureTaken", onPictureTaken);
      this.offOnProcessingChange = DeviceEventEmitter.addListener("onProcessingChange", onProcessing);
    }
  }

  async getAndroidPermissions() {
    if (Platform.OS !== "android") return;
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
        PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
      ]);

      if (granted["android.permission.READ_EXTERNAL_STORAGE"] === PermissionsAndroid.RESULTS.GRANTED && 
          granted["android.permission.WRITE_EXTERNAL_STORAGE"] === PermissionsAndroid.RESULTS.GRANTED){
            this.setState({ permissionsAuthorized: true });
          }else{
            this.onPermissionsDenied();
          } 
    } catch (err) {
      this.onPermissionsDenied();
    }
  }

  sendOnPictureTakenEvent(event) {
    return this.props.onPictureTaken(event.nativeEvent);
  }

  sendOnRectanleDetectEvent(event) {
    if (!this.props.onRectangleDetect) return null;
    return this.props.onRectangleDetect(event.nativeEvent);
  }

  getImageQuality() {
    if (!this.props.quality) return 1;
    if (this.props.quality > 1) return 1;
    if (this.props.quality < 0.1) return 0.1;
    return this.props.quality;
  }

  componentWillUnmount() {
    if (Platform.OS === "android") {
      if(this.offOnPictureTaken){
        this.offOnPictureTaken.remove();
      }
      if(this.offOnProcessingChange){
        this.offOnProcessingChange.remove();
      }
    }
    // 手动停止相机，释放相机资源
    NativeModules.RNPdfScannerManager.stop();

  }

  capture() {
    if (this.state.permissionsAuthorized){
      NativeModules.RNPdfScannerManager.capture();
    }
  }

  render() {
    if (!this.state.permissionsAuthorized) {
      return null
    }
    return (
      <RNPdfScanner
        {...this.props}
        onPictureTaken={this.sendOnPictureTakenEvent.bind(this)}
        onRectangleDetect={this.sendOnRectanleDetectEvent.bind(this)}
        useFrontCam={this.props.useFrontCam || false}
        brightness={this.props.brightness || 0}
        saturation={this.props.saturation || 1}
        contrast={this.props.contrast || 1}
        quality={this.getImageQuality()}
        detectionCountBeforeCapture={
          this.props.detectionCountBeforeCapture || 5
        }
        detectionRefreshRateInMS={this.props.detectionRefreshRateInMS || 50}
      />
    );
  }
}

DocumentScanner.propTypes = {
  onPictureTaken: PropTypes.func,
  onRectangleDetect: PropTypes.func,
  overlayColor: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  enableTorch: PropTypes.bool,
  useFrontCam: PropTypes.bool,
  saturation: PropTypes.number,
  brightness: PropTypes.number,
  contrast: PropTypes.number,
  detectionCountBeforeCapture: PropTypes.number,
  detectionRefreshRateInMS: PropTypes.number,
  quality: PropTypes.number,
  documentAnimation: PropTypes.bool,
  noGrayScale: PropTypes.bool,
  manualOnly: PropTypes.bool,
  ...View.propTypes // include the default view properties
};
