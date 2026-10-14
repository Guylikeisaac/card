import 'package:flutter/material.dart';

class ChoiceOption {
  const ChoiceOption(this.title, {this.description, this.icon});
  final String title;
  final String? description;
  final IconData? icon;
}

const kIntents = [
  ChoiceOption("I'm actively looking for a job"),
  ChoiceOption("I'm passively open to offers"),
  ChoiceOption("I'm here to hire / network"),
];

const kSetupModes = [
  ChoiceOption(
    'Upload Resume',
    description:
        "We'll auto-fill your experience, skills, and education from your resume.",
    icon: Icons.file_upload_outlined,
  ),
  ChoiceOption(
    'Fill Manually',
    description: 'Enter your details step by step — takes about 5 minutes.',
    icon: Icons.edit_outlined,
  ),
];

const kLevels = [
  ChoiceOption(
    'Experienced Professional',
    description:
        'I have work experience and am currently employed or have been in the past.',
    icon: Icons.work_outline_rounded,
  ),
  ChoiceOption(
    'Student / Fresher',
    description:
        "I'm a student, recent graduate, or have less than 1 year of work experience.",
    icon: Icons.school_outlined,
  ),
];

const kNoticePeriods = [
  ChoiceOption('Immediate Joinee'),
  ChoiceOption('0-15 days'),
  ChoiceOption('1 month'),
  ChoiceOption('2 month'),
  ChoiceOption('3 month'),
  ChoiceOption('more than 3 month'),
];

const kGenders = [
  ChoiceOption('Male'),
  ChoiceOption('Female'),
  ChoiceOption('Non-binary'),
  ChoiceOption('Prefer not to say'),
];

const kCities = [
  'Bengaluru, Karnataka',
  'Mumbai, Maharashtra',
  'Delhi',
  'New Delhi, Delhi',
  'Hyderabad, Telangana',
  'Pune, Maharashtra',
  'Chennai, Tamil Nadu',
  'Gurugram, Haryana',
  'Noida, Uttar Pradesh',
  'Kolkata, West Bengal',
  'Ahmedabad, Gujarat',
  'Jaipur, Rajasthan',
  'Chandigarh',
  'Kochi, Kerala',
  'Indore, Madhya Pradesh',
  'Lucknow, Uttar Pradesh',
  'Coimbatore, Tamil Nadu',
  'Remote',
];

const kDepartments = [
  'Engineering - Software & QA',
  'Product Management',
  'Design',
  'Data Science & Analytics',
  'Sales & Business Development',
  'Marketing & Communication',
  'Finance & Accounting',
  'Human Resources',
  'Operations',
  'Customer Success',
  'Consulting',
  'Other',
];

const kIndustries = [
  'IT Services & Consulting',
  'Software Product',
  'Internet / E-commerce',
  'FinTech',
  'BFSI',
  'EdTech',
  'HealthTech',
  'Manufacturing',
  'Media & Entertainment',
  'Telecom',
  'Retail',
  'Automobile',
  'Other',
];

const kEmploymentTypes = [
  'Full-time',
  'Part-time',
  'Contract',
  'Internship',
  'Freelance',
];

const kRoles = [
  'Software Engineer',
  'Frontend Engineer',
  'Backend Engineer',
  'Full Stack Engineer',
  'Mobile Engineer',
  'Product Engineer',
  'Product Manager',
  'Product Designer',
  'UI/UX Designer',
  'Data Scientist',
  'Data Analyst',
  'ML Engineer',
  'DevOps Engineer',
  'QA Engineer',
  'Engineering Manager',
  'Business Analyst',
  'Marketing Manager',
  'Sales Executive',
];

const kDreamRoleSuggestions = [
  'Software Engineer',
  'Product Designer',
  'Product Manager',
  'Data Scientist',
  'Founder',
];

const kSkills = [
  'Python',
  'Product Management',
  'UI/UX Design',
  'Figma',
  'Data Analysis',
  'Digital Marketing',
  'JavaScript',
  'Project Management',
  'Financial Modeling',
  'React',
  'Flutter',
  'Java',
  'SQL',
  'Machine Learning',
  'Node.js',
  'TypeScript',
  'AWS',
  'Go',
  'Communication',
  'Leadership',
];

class Interest {
  const Interest(this.label, this.icon);
  final String label;
  final IconData icon;
}

const kInterests = [
  Interest('Career', Icons.show_chart_rounded),
  Interest('Entrepreneurship', Icons.person_search_outlined),
  Interest('News & Current Events', Icons.newspaper_outlined),
  Interest('Inspirational', Icons.auto_awesome_outlined),
  Interest('Technology', Icons.dns_outlined),
  Interest('Industry Insights', Icons.apartment_outlined),
  Interest('Design', Icons.category_outlined),
  Interest('Networking', Icons.lan_outlined),
  Interest('Social Impact', Icons.groups_outlined),
  Interest('Finance', Icons.payments_outlined),
  Interest('Sports', Icons.sports_basketball_outlined),
  Interest('Learning', Icons.local_library_outlined),
];
