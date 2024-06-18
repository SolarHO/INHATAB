import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/home_page_model.dart';
export '../model/home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0x4C181BF8),
          automaticallyImplyLeading: false,
          title: Text(
            'INHA TAB',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).accent4,
                  letterSpacing: 0,
                ),
          ),
          actions: [
            Align(
              alignment: AlignmentDirectional(0, 0),
              child: Padding(
                padding: EdgeInsets.all(18), // 기존의 패딩 유지
                child: IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.solidUserCircle,
                    color: FlutterFlowTheme.of(context).accent4,
                    size: 24,
                  ),
                  alignment: Alignment(0.0, -1.0), // 아이콘을 위로 조정
                  padding: EdgeInsets.zero, // 기본 패딩을 제거
                  onPressed: () {
                    context.go('/myProfile');
                  },
                ),
              ),
            ),
          ],
          centerTitle: true,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 500,
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 40),
                          child: PageView(
                            controller: _model.pageViewController ??=
                                PageController(initialPage: 0),
                            scrollDirection: Axis.horizontal,
                            children: [
                              ClipRRect(
                                child: Image(
                                  image: AssetImage('v_2.jpg'),
                                  width: 300,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ClipRRect(
                                child: Image(
                                  image: AssetImage('campus2.jpg'),
                                  width: 300,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ClipRRect(
                                child: Image(
                                  image: AssetImage('Photo_1.jpg'),
                                  width: 300,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(-1, 1),
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
                            child: smooth_page_indicator.SmoothPageIndicator(
                              controller: _model.pageViewController ??=
                                  PageController(initialPage: 0),
                              count: 3,
                              axisDirection: Axis.horizontal,
                              onDotClicked: (i) async {
                                await _model.pageViewController!.animateToPage(
                                  i,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.ease,
                                );
                                setState(() {});
                              },
                              effect: smooth_page_indicator.ExpandingDotsEffect(
                                expansionFactor: 3,
                                spacing: 8,
                                radius: 16,
                                dotWidth: 16,
                                dotHeight: 8,
                                dotColor: FlutterFlowTheme.of(context).accent1,
                                activeDotColor:
                                    FlutterFlowTheme.of(context).primary,
                                paintStyle: PaintingStyle.fill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(5, 10, 5, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomContainer(
                          iconData: Icons.apartment_rounded,
                          text: '홈페이지',
                          url: 'https://www.inhatc.ac.kr'),
                      CustomContainer(
                          iconData: Icons.campaign,
                          text: '학생공지',
                          url:
                              'https://www.inhatc.ac.kr/kr/460/subview.do?enc=Zm5jdDF8QEB8JTJGY29tYkJicyUyRmtyJTJGMiUyRmxpc3QuZG8lM0Y%3D'),
                      CustomContainer(
                          iconData: Icons.monitor_sharp,
                          text: '종합정보',
                          url: 'https://icims.inhatc.ac.kr/intra/login.jsp'),
                      CustomContainer(
                          iconData: Icons.ondemand_video_rounded,
                          text: '이러닝',
                          url: 'https://cyber.inhatc.ac.kr/'),
                      CustomContainer(
                          iconData: Icons.call,
                          text: '전화번호',
                          url: 'https://www.inhatc.ac.kr/kr/166/subview.do'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(5, 10, 5, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomContainer(
                          iconData: Icons.calendar_month_outlined,
                          text: '학사일정',
                          url:
                              'https://www.inhatc.ac.kr/kr/123/subview.do?enc=Zm5jdDF8QEB8JTJGc2NoZHVsbWFuYWdlJTJGa3IlMkYzJTJGdmlldy5kbyUzRg%3D%3D'),
                      CustomContainer(
                          iconData: Icons.pin_drop_outlined,
                          text: '학교지도',
                          url: 'https://www.inhatc.ac.kr/kr/103/subview.do'),
                      CustomContainer(
                          iconData: Icons.restaurant,
                          text: '식당메뉴',
                          url: 'https://www.inhatc.ac.kr/kr/485/subview.do'),
                      CustomContainer(
                          iconData: Icons.auto_stories,
                          text: '도서관',
                          url:
                              'https://library.inhatc.ac.kr/Cheetah/INHA/Index/'),
                      CustomContainer(
                          iconData: Icons.directions_bus,
                          text: '셔틀버스',
                          url:
                              'https://library.inhatc.ac.kr/Cheetah/INHA/Index/'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(10, 7, 10, 7),
                  child: WeatherDisplayWidget(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomContainer extends StatelessWidget {
  final IconData iconData;
  final String text;
  final String url;

  CustomContainer(
      {required this.iconData, required this.text, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 70,
      decoration: BoxDecoration(
        color: Color(0xFF1632BA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
            child: FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 5,
              borderWidth: 1,
              buttonSize: 40,
              fillColor: Color(0xFF3A58FF),
              icon: Icon(
                iconData,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () async {
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          ),
          Text(
            text,
            style: FlutterFlowTheme.of(context).titleSmall.override(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

class WeatherDisplayWidget extends StatefulWidget {
  @override
  _WeatherDisplayWidgetState createState() => _WeatherDisplayWidgetState();
}

class _WeatherDisplayWidgetState extends State<WeatherDisplayWidget> {
  late WeatherFactory weatherFactory;
  Weather? currentWeather;
  List<Weather> forecast = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory("480bb59d3adafa1750f9286c49d3f6bc");
    fetchWeather();
  }

  void fetchWeather() async {
    try {
      // 현재 날씨 데이터 가져오기
      currentWeather =
          await weatherFactory.currentWeatherByLocation(37.4508, 126.6572);
      // 3시간 간격으로 날씨 예보 데이터 가져오기
      var fiveDayForecast =
          await weatherFactory.fiveDayForecastByLocation(37.4508, 126.6572);
      forecast = fiveDayForecast.take(2).toList();
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData getWeatherIcon(String description) {
    // 날씨 설명을 기반으로 적절한 Flutter 아이콘 반환
    if (description.contains('clear')) {
      return Icons.wb_sunny;
    } else if (description.contains('cloud')) {
      return Icons.cloud;
    } else if (description.contains('rain')) {
      return Icons.beach_access;
    } else if (description.contains('snow')) {
      return Icons.ac_unit;
    } else {
      return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentWeather != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '지금 학교 날씨',
                            style: TextStyle(fontSize: 15),
                          ),
                          Text(
                            '${currentWeather!.temperature!.celsius!.toStringAsFixed(1)}°C',
                            style: TextStyle(
                                fontSize: 35, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '체감온도: ${currentWeather!.tempFeelsLike!.celsius!.toStringAsFixed(1)}°C',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    const Color.fromARGB(255, 110, 110, 110)),
                          ),
                          Text(
                            '최저: ${currentWeather!.tempMin!.celsius!.toStringAsFixed(1)}°C / 최고: ${currentWeather!.tempMax!.celsius!.toStringAsFixed(1)}°C',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    const Color.fromARGB(255, 110, 110, 110)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(
                            getWeatherIcon(currentWeather!.weatherDescription!),
                            size: 50,
                            color: Colors.blue,
                          ),
                          Text(
                            '풍속: ${currentWeather!.windSpeed} km/h',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '습도: ${currentWeather!.humidity}%',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ...forecast.map((weather) {
                  return ListTile(
                    title: Text('${weather.date?.hour}:00',
                        style: TextStyle(color: Colors.grey)),
                    leading: Icon(getWeatherIcon(weather.weatherDescription!),
                        color: Colors.grey),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            '${weather.temperature!.celsius!.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
  }
}
