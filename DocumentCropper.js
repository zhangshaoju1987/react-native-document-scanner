import React, { Component } from 'react';
import {NativeModules,PanResponder,Dimensions,Image,View,Animated,PixelRatio} from 'react-native';
import Svg, { Polygon } from 'react-native-svg';

const AnimatedPolygon = Animated.createAnimatedComponent(Polygon);
const viewWidth =  Dimensions.get('window').width;
/**
 * 基于四个矩形点进行裁剪,获取到精准的文档图片
 */
export default class DocumentCropper extends Component {
    constructor(props) {
        super(props);
        this.state = {
            viewWidth,
            viewHeight:viewWidth * (props.height / props.width), // 按实际的图片的宽高比例进行展示
            height: props.height,
            width: props.width,
            image: props.initialImage,
            moving: false,
        };
        const cornerPoint = props.rectangleCoordinates;// 四个角点
        this.state = {
            ...this.state,
            topLeft: new Animated.ValueXY(cornerPoint? this.imageCoordinatesToViewCoordinates(cornerPoint.topLeft,"topLeft"): { x: 100, y: 100 }),
            topRight: new Animated.ValueXY(cornerPoint? this.imageCoordinatesToViewCoordinates(cornerPoint.topRight,"topRight"): { x: viewWidth - 100, y: 100 }),
            bottomLeft: new Animated.ValueXY(cornerPoint? this.imageCoordinatesToViewCoordinates(cornerPoint.bottomLeft,"bottomLeft"): { x: 100, y: this.state.viewHeight - 100 },),
            bottomRight: new Animated.ValueXY(cornerPoint? this.imageCoordinatesToViewCoordinates(cornerPoint.bottomRight,"bottomRight"): {x: viewWidth - 100,y: this.state.viewHeight - 100})
        };
        this.state = {
            ...this.state,
            overlayPositions: 
            `${this.state.topLeft.x._value},${this.state.topLeft.y._value} 
            ${this.state.topRight.x._value},${this.state.topRight.y._value} 
            ${this.state.bottomRight.x._value},${this.state.bottomRight.y._value} 
            ${this.state.bottomLeft.x._value},${this.state.bottomLeft.y._value}`,
        };

        this.panResponderTopLeft = this.createPanResponser(this.state.topLeft);
        this.panResponderTopRight = this.createPanResponser(this.state.topRight);
        this.panResponderBottomLeft = this.createPanResponser(this.state.bottomLeft);
        this.panResponderBottomRight = this.createPanResponser(this.state.bottomRight);
    }

    createPanResponser(corner) {
        return PanResponder.create({
            onStartShouldSetPanResponder: () => true,
            onPanResponderMove: Animated.event([
                null,
                {
                    dx: corner.x,
                    dy: corner.y,
                },
            ],{ useNativeDriver: true }),
            onPanResponderRelease: () => {
                corner.flattenOffset();
                this.updateOverlayString();
            },
            onPanResponderGrant: () => {
                corner.setOffset({ x: corner.x._value, y: corner.y._value });
                corner.setValue({ x: 0, y: 0 });
            }
        });
    }

    crop() {
        const coordinates = {
            topLeft: this.viewCoordinatesToImageCoordinates(this.state.topLeft,"topLeft"),
            topRight: this.viewCoordinatesToImageCoordinates(this.state.topRight,"topRight"),
            bottomLeft: this.viewCoordinatesToImageCoordinates(this.state.bottomLeft,"bottomLeft"),
            bottomRight: this.viewCoordinatesToImageCoordinates(this.state.bottomRight,"bottomRight"),
            height: this.state.height,
            width: this.state.width,
        };
        NativeModules.RNPdfScannerManager.crop(
            coordinates,
            this.state.image,
            (err, res) => this.props.updateImage(res.image, coordinates),
        );
    }

    updateOverlayString() {
        this.setState({
            overlayPositions: 
            `${this.state.topLeft.x._value},${this.state.topLeft.y._value} 
            ${this.state.topRight.x._value},${this.state.topRight.y._value} 
            ${this.state.bottomRight.x._value},${this.state.bottomRight.y._value} 
            ${this.state.bottomLeft.x._value},${this.state.bottomLeft.y._value}`,
        });
    }
    /**
     * 将图片点位缩放成容器支持的点位
     * @param {*} corner 
     * @param {*} label 
     * @returns 
     */
    imageCoordinatesToViewCoordinates(corner,label) {

        // 图片的宽高,需要除以像素密度才能和屏幕宽度进行比较
        // 需要把图片宽度像素转成dp才能进行比较
        const imageW = this.state.width/(PixelRatio.get()/1.045);// 部分手机像素密度虚高，比如小米手机
        const imageH = this.state.height/(PixelRatio.get()/1.045);
        const newCorner = {
            x: corner.x * (imageW/this.state.viewWidth ),
            y: corner.y * (imageH/this.state.viewHeight)
        };

        if(label == "topLeft"){
            // RN中的尺寸单位为dp，而设计稿中的单位为px
            console.log("原始图片大小",this.state.width,this.state.height,PixelRatio.roundToNearestPixel(this.state.width));
            console.log("Dimensions.get('window').",Dimensions.get('window').scale);
            console.log("转换比例",imageW/this.state.viewWidth,imageH/this.state.viewHeight);
            console.log("转换前,角点位置",label,corner);
            console.log("转换后,角点位置",label,newCorner);
            console.log("PixelRatio=",PixelRatio.get(),"FontScale=",PixelRatio.getFontScale())
        }
        
        return newCorner;
    }
    /**
     * 还原成真实的图片点位
     * @param {*} corner 
     * @returns 
     */
    viewCoordinatesToImageCoordinates(corner,label) {

        const imageW = this.state.width/(PixelRatio.get()/1.045);// 部分手机像素密度虚高，比如小米手机
        const imageH = this.state.height/(PixelRatio.get()/1.045);

        const newCorner = {
            x: Math.ceil((corner.x._value * this.state.viewWidth) /imageW),
            y: Math.ceil((corner.y._value * this.state.viewHeight)/ imageH),
        };
        if(label == "topLeft"){
            console.log("----------转换前,角点位置",label,corner);
            console.log("----------转换后,角点位置",label,newCorner);
        }
        return newCorner;
    }

    render() {
        return (
            <View
                style={{
                    flex: 1,
                    alignItems: 'center',
                    justifyContent: 'flex-end',
                }}
            >
                <View
                    style={[
                        s(this.props).cropContainer,
                        { height: this.state.viewHeight },
                    ]}
                >
                    <Image
                        style={[
                            s(this.props).image,
                            { height: this.state.viewHeight },
                        ]}
                        resizeMode="contain"
                        source={{ uri: this.state.image }}
                    />
                    <Svg
                        height={this.state.viewHeight}
                        width={Dimensions.get('window').width}
                        style={{ position: 'absolute', left: 0, top: 0 }}
                    >
                        <AnimatedPolygon
                            ref={(ref) => (this.polygon = ref)}
                            fill={this.props.overlayColor || 'blue'}
                            fillOpacity={this.props.overlayOpacity || 0.5}
                            stroke={this.props.overlayStrokeColor || 'blue'}
                            points={this.state.overlayPositions}
                            strokeWidth={this.props.overlayStrokeWidth || 3}
                        />
                    </Svg>
                    <Animated.View
                        {...this.panResponderTopLeft.panHandlers}
                        style={[
                            this.state.topLeft.getLayout(),
                            s(this.props).handler,
                        ]}
                    >
                        <View
                            style={[
                                s(this.props).handlerI,
                                { left: -10, top: -10 },
                            ]}
                        />
                        <View
                            style={[
                                s(this.props).handlerRound,
                                { left: 31, top: 31 },
                            ]}
                        />
                    </Animated.View>
                    <Animated.View
                        {...this.panResponderTopRight.panHandlers}
                        style={[
                            this.state.topRight.getLayout(),
                            s(this.props).handler,
                        ]}
                    >
                        <View
                            style={[
                                s(this.props).handlerI,
                                { left: 10, top: -10 },
                            ]}
                        />
                        <View
                            style={[
                                s(this.props).handlerRound,
                                { right: 31, top: 31 },
                            ]}
                        />
                    </Animated.View>
                    <Animated.View
                        {...this.panResponderBottomLeft.panHandlers}
                        style={[
                            this.state.bottomLeft.getLayout(),
                            s(this.props).handler,
                        ]}
                    >
                        <View
                            style={[
                                s(this.props).handlerI,
                                { left: -10, top: 10 },
                            ]}
                        />
                        <View
                            style={[
                                s(this.props).handlerRound,
                                { left: 31, bottom: 31 },
                            ]}
                        />
                    </Animated.View>
                    <Animated.View
                        {...this.panResponderBottomRight.panHandlers}
                        style={[
                            this.state.bottomRight.getLayout(),
                            s(this.props).handler,
                        ]}
                    >
                        <View
                            style={[
                                s(this.props).handlerI,
                                { left: 10, top: 10 },
                            ]}
                        />
                        <View
                            style={[
                                s(this.props).handlerRound,
                                { right: 31, bottom: 31 },
                            ]}
                        />
                    </Animated.View>
                </View>
            </View>
        );
    }
}

const s = (props) => ({
    handlerI: {
        borderRadius: 0,
        height: 20,
        width: 20,
        backgroundColor: props.handlerColor || 'blue',
    },
    handlerRound: {
        width: 39,
        position: 'absolute',
        height: 39,
        borderRadius: 100,
        backgroundColor: props.handlerColor || 'blue',
    },
    image: {
        width: Dimensions.get('window').width,
        position: 'absolute',
    },
    bottomButton: {
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'blue',
        width: 70,
        height: 70,
        borderRadius: 100,
    },
    handler: {
        height: 140,
        width: 140,
        overflow: 'visible',
        marginLeft: -70,
        marginTop: -70,
        alignItems: 'center',
        justifyContent: 'center',
        position: 'absolute',
    },
    cropContainer: {
        position: 'absolute',
        left: 0,
        width: Dimensions.get('window').width,
        top: 0,
    },
});