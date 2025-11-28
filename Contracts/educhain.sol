// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Educhain - Simple on-chain course completion tracker
/// @notice Teachers can create courses and issue completion records to students.
contract Educhain {
    struct Course {
        string title;
        string description;
        address teacher;
        bool isActive;
    }

    struct Completion {
        uint256 courseId;
        address student;
        uint256 completedAt;
    }

    uint256 public courseCount;
    mapping(uint256 => Course) public courses;
    mapping(address => Completion[]) public completions;

    event CourseCreated(uint256 indexed courseId, string title, address indexed teacher);
    event CourseStatusUpdated(uint256 indexed courseId, bool isActive);
    event CourseCompleted(uint256 indexed courseId, address indexed student, uint256 timestamp);

    modifier onlyTeacher(uint256 _courseId) {
        require(courses[_courseId].teacher == msg.sender, "Not course teacher");
        _;
    }

    /// @notice Create a new course on Educhain.
    /// @param _title Short title of the course.
    /// @param _description Brief description of the course.
    function createCourse(
        string calldata _title,
        string calldata _description
    ) external {
        require(bytes(_title).length > 0, "Title required");

        courseCount += 1;
        courses[courseCount] = Course({
            title: _title,
            description: _description,
            teacher: msg.sender,
            isActive: true
        });

        emit CourseCreated(courseCount, _title, msg.sender);
    }

    /// @notice Activate or deactivate an existing course.
    /// @param _courseId Id of the course.
    /// @param _isActive New active status.
    function setCourseStatus(
        uint256 _courseId,
        bool _isActive
    ) external onlyTeacher(_courseId) {
        require(_courseId > 0 && _courseId <= courseCount, "Invalid course id");

        courses[_courseId].isActive = _isActive;
        emit CourseStatusUpdated(_courseId, _isActive);
    }

    /// @notice Mark a student as having completed a course.
    /// @dev Called by the teacher of the course.
    /// @param _courseId Id of the course.
    /// @param _student Address of the student.
    function markCompleted(
        uint256 _courseId,
        address _student
    ) external onlyTeacher(_courseId) {
        require(_courseId > 0 && _courseId <= courseCount, "Invalid course id");
        require(courses[_courseId].isActive, "Course not active");
        require(_student != address(0), "Invalid student");

        completions[_student].push(
            Completion({
                courseId: _courseId,
                student: _student,
                completedAt: block.timestamp
            })
        );

        emit CourseCompleted(_courseId, _student, block.timestamp);
    }

    /// @notice Get how many courses a student has completed.
    /// @param _student Address of the student.
    function getCompletionCount(address _student) external view returns (uint256) {
        return completions[_student].length;
    }

    /// @notice Get a specific completion record for a student by index.
    /// @param _student Address of the student.
    /// @param _index Index in the student's completion list.
    function getCompletionByIndex(
        address _student,
        uint256 _index
    ) external view returns (uint256 courseId, uint256 completedAt) {
        require(_index < completions[_student].length, "Index out of range");
        Completion storage c = completions[_student][_index];
        return (c.courseId, c.completedAt);
    }
}
