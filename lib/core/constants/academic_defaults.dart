import 'package:presenza/data/models/course_model.dart';

/// Centralized repository of academic default data, course catalogues, admission years,
/// and batch helpers shared across Registration, Teacher Attendance, and Academic Management.
class AcademicDefaults {
  AcademicDefaults._();

  /// Comprehensive list of standard university courses and degree programs.
  static const List<CourseModel> defaultCourses = [
    // ── Engineering & Technology ─────────────────────────────────────────
    CourseModel(
      id: 'course-btech-cse',
      name: 'B.Tech Computer Science & Engineering (CSE)',
      code: 'BTECH-CSE',
      departmentId: 'dept-cse',
      totalSemesters: 8,
      description: 'Undergraduate engineering in computing, algorithms, and software design.',
    ),
    CourseModel(
      id: 'course-btech-aids',
      name: 'B.Tech Artificial Intelligence & Data Science (AI/DS)',
      code: 'BTECH-AIDS',
      departmentId: 'dept-cse',
      totalSemesters: 8,
      description: 'Specialized program in machine learning, deep learning, and data analytics.',
    ),
    CourseModel(
      id: 'course-btech-it',
      name: 'B.Tech Information Technology (IT)',
      code: 'BTECH-IT',
      departmentId: 'dept-it',
      totalSemesters: 8,
      description: 'Undergraduate engineering in networking, databases, and enterprise systems.',
    ),
    CourseModel(
      id: 'course-btech-ece',
      name: 'B.Tech Electronics & Communication (ECE)',
      code: 'BTECH-ECE',
      departmentId: 'dept-ece',
      totalSemesters: 8,
      description: 'Undergraduate program in circuits, embedded systems, and communication.',
    ),
    CourseModel(
      id: 'course-btech-ee',
      name: 'B.Tech Electrical Engineering (EE)',
      code: 'BTECH-EE',
      departmentId: 'dept-ee',
      totalSemesters: 8,
      description: 'Power systems, electrical drives, and renewable energy technologies.',
    ),
    CourseModel(
      id: 'course-btech-me',
      name: 'B.Tech Mechanical Engineering (ME)',
      code: 'BTECH-ME',
      departmentId: 'dept-me',
      totalSemesters: 8,
      description: 'Thermodynamics, robotics, manufacturing, and mechanics.',
    ),
    CourseModel(
      id: 'course-btech-ce',
      name: 'B.Tech Civil Engineering (CE)',
      code: 'BTECH-CE',
      departmentId: 'dept-ce',
      totalSemesters: 8,
      description: 'Structural engineering, geotechnics, and infrastructure design.',
    ),
    CourseModel(
      id: 'course-btech-bt',
      name: 'B.Tech Biotechnology (BT)',
      code: 'BTECH-BT',
      departmentId: 'dept-bt',
      totalSemesters: 8,
      description: 'Biomolecular engineering, genetics, and bioprocess technology.',
    ),
    CourseModel(
      id: 'course-mtech-cse',
      name: 'M.Tech Computer Science & Engineering',
      code: 'MTECH-CSE',
      departmentId: 'dept-cse',
      totalSemesters: 4,
      description: 'Postgraduate specialization in advanced computing and distributed systems.',
    ),
    CourseModel(
      id: 'course-mtech-dsai',
      name: 'M.Tech Data Science & AI',
      code: 'MTECH-DSAI',
      departmentId: 'dept-cse',
      totalSemesters: 4,
      description: 'Advanced postgraduate program in machine learning and data engineering.',
    ),
    CourseModel(
      id: 'course-mtech-vlsi',
      name: 'M.Tech VLSI & Embedded Systems',
      code: 'MTECH-VLSI',
      departmentId: 'dept-ece',
      totalSemesters: 4,
      description: 'Semiconductor design, microelectronics, and hardware description.',
    ),

    // ── Computer Applications ────────────────────────────────────────────
    CourseModel(
      id: 'course-bca',
      name: 'Bachelor of Computer Applications (BCA)',
      code: 'BCA',
      departmentId: 'dept-ca',
      totalSemesters: 6,
      description: 'Undergraduate application development, web tech, and system management.',
    ),
    CourseModel(
      id: 'course-mca',
      name: 'Master of Computer Applications (MCA)',
      code: 'MCA',
      departmentId: 'dept-ca',
      totalSemesters: 4,
      description: 'Postgraduate professional software architecture and enterprise computing.',
    ),

    // ── Management & Business ────────────────────────────────────────────
    CourseModel(
      id: 'course-bba',
      name: 'Bachelor of Business Administration (BBA)',
      code: 'BBA',
      departmentId: 'dept-mgmt',
      totalSemesters: 6,
      description: 'Foundations of management, marketing, human resources, and business finance.',
    ),
    CourseModel(
      id: 'course-mba',
      name: 'Master of Business Administration (MBA)',
      code: 'MBA',
      departmentId: 'dept-mgmt',
      totalSemesters: 4,
      description: 'Advanced strategic management, analytics, leadership, and operations.',
    ),
    CourseModel(
      id: 'course-bcom',
      name: 'Bachelor of Commerce (B.Com Hons)',
      code: 'BCOM',
      departmentId: 'dept-commerce',
      totalSemesters: 6,
      description: 'Accounting, corporate finance, taxation, and economic auditing.',
    ),
    CourseModel(
      id: 'course-mcom',
      name: 'Master of Commerce (M.Com)',
      code: 'MCOM',
      departmentId: 'dept-commerce',
      totalSemesters: 4,
      description: 'Advanced financial theory, quantitative commerce, and taxation laws.',
    ),

    // ── Law & Legal Studies ──────────────────────────────────────────────
    CourseModel(
      id: 'course-bba-llb',
      name: 'BBA LL.B. (Integrated Honours)',
      code: 'BBA-LLB',
      departmentId: 'dept-law',
      totalSemesters: 10,
      description: 'Integrated corporate management and jurisprudence programme.',
    ),
    CourseModel(
      id: 'course-ba-llb',
      name: 'BA LL.B. (Integrated Honours)',
      code: 'BA-LLB',
      departmentId: 'dept-law',
      totalSemesters: 10,
      description: 'Integrated humanities and comprehensive legal jurisprudence programme.',
    ),
    CourseModel(
      id: 'course-llb',
      name: 'Bachelor of Laws (LL.B.)',
      code: 'LLB',
      departmentId: 'dept-law',
      totalSemesters: 6,
      description: 'Three-year graduate degree in legal practice, constitutional law, and litigation.',
    ),
    CourseModel(
      id: 'course-llm',
      name: 'Master of Laws (LL.M.)',
      code: 'LLM',
      departmentId: 'dept-law',
      totalSemesters: 4,
      description: 'Advanced legal scholarship in intellectual property, corporate, and criminal law.',
    ),

    // ── Sciences & Integrated Dual Degrees ───────────────────────────────
    CourseModel(
      id: 'course-bs-ms',
      name: 'BS-MS Dual Degree (Integrated Sciences)',
      code: 'BS-MS',
      departmentId: 'dept-science',
      totalSemesters: 10,
      description: 'Five-year integrated dual degree in foundational and applied scientific research.',
    ),
    CourseModel(
      id: 'course-bsc-cs',
      name: 'B.Sc Computer Science / Data Science',
      code: 'BSC-CS',
      departmentId: 'dept-science',
      totalSemesters: 6,
      description: 'Core computing theory, statistical modeling, and computational methods.',
    ),
    CourseModel(
      id: 'course-bsc-pcm',
      name: 'B.Sc Physical Sciences (PCM)',
      code: 'BSC-PCM',
      departmentId: 'dept-science',
      totalSemesters: 6,
      description: 'Physics, Chemistry, and Applied Mathematics theoretical foundations.',
    ),
    CourseModel(
      id: 'course-msc-ds',
      name: 'M.Sc Data Science & Analytics',
      code: 'MSC-DS',
      departmentId: 'dept-science',
      totalSemesters: 4,
      description: 'Postgraduate big data engineering, Bayesian statistics, and predictive modeling.',
    ),

    // ── Pharmacy & Health Sciences ───────────────────────────────────────
    CourseModel(
      id: 'course-bpharm',
      name: 'Bachelor of Pharmacy (B.Pharm)',
      code: 'BPHARM',
      departmentId: 'dept-pharmacy',
      totalSemesters: 8,
      description: 'Pharmaceutical chemistry, pharmacology, dosage design, and clinical pharmacy.',
    ),
    CourseModel(
      id: 'course-mpharm',
      name: 'Master of Pharmacy (M.Pharm)',
      code: 'MPHARM',
      departmentId: 'dept-pharmacy',
      totalSemesters: 4,
      description: 'Advanced drug formulation, analytical chemistry, and regulatory affairs.',
    ),

    // ── Design & Architecture ────────────────────────────────────────────
    CourseModel(
      id: 'course-bdes',
      name: 'Bachelor of Design (B.Des)',
      code: 'BDES',
      departmentId: 'dept-design',
      totalSemesters: 8,
      description: 'User experience, product ergonomics, visual communication, and industrial design.',
    ),
    CourseModel(
      id: 'course-mdes',
      name: 'Master of Design (M.Des)',
      code: 'MDES',
      departmentId: 'dept-design',
      totalSemesters: 4,
      description: 'Design thinking, strategic UX architecture, and speculative design research.',
    ),

    // ── Doctoral Research ────────────────────────────────────────────────
    CourseModel(
      id: 'course-phd',
      name: 'Ph.D. / Doctoral Research',
      code: 'PHD',
      departmentId: 'dept-research',
      totalSemesters: 6,
      description: 'Doctoral dissertation and original contributions to academic literature.',
    ),
  ];

  /// Standard list of admission / batch years.
  static const List<int> defaultYears = [
    2020,
    2021,
    2022,
    2023,
    2024,
    2025,
    2026,
    2027,
    2028,
    2029,
    2030,
  ];

  /// Standard list of section identifiers.
  static const List<String> defaultSections = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  /// Default categories for course filtering.
  static const List<String> courseCategories = [
    'All',
    'Engineering',
    'Sciences & Dual Degree',
    'Computer Apps',
    'Management',
    'Law',
    'Pharmacy',
    'Design',
    'Doctoral',
  ];

  /// Category determination helper.
  static bool matchesCategory(CourseModel course, String category) {
    if (category == 'All') return true;
    final code = course.code.toUpperCase();
    switch (category) {
      case 'Engineering':
        return code.contains('BTECH') || code.contains('MTECH');
      case 'Sciences & Dual Degree':
        return code.contains('BS-MS') || code.contains('BSC') || code.contains('MSC');
      case 'Computer Apps':
        return code.contains('BCA') || code.contains('MCA');
      case 'Management':
        return code.contains('BBA') || code.contains('MBA') || code.contains('COM');
      case 'Law':
        return code.contains('LL');
      case 'Pharmacy':
        return code.contains('PHARM');
      case 'Design':
        return code.contains('DES');
      case 'Doctoral':
        return code.contains('PHD');
      default:
        return true;
    }
  }

  /// Finds a course by ID from the default catalog.
  static CourseModel? findCourseById(String id) {
    return defaultCourses.where((c) => c.id == id).firstOrNull;
  }

  /// Generates a standardized batch ID given a courseId, admission year, and section.
  static String formatBatchId(String courseId, int year, String section) {
    return 'batch_${courseId}_${year}_${section.toLowerCase()}';
  }

  /// Generates a human-friendly batch title.
  static String formatBatchName(String courseCode, int year, String section) {
    return '$courseCode • Batch $year (Sec $section)';
  }

  /// Creates a synthetic [BatchModel] instance when an explicit Firestore record is not pre-populated.
  static BatchModel createSyntheticBatch({
    required String courseId,
    required int year,
    required String section,
    String? courseCode,
  }) {
    final code = courseCode ?? findCourseById(courseId)?.code ?? courseId;
    return BatchModel(
      id: formatBatchId(courseId, year, section),
      name: formatBatchName(code, year, section),
      courseId: courseId,
      year: year,
      section: section,
    );
  }
}
