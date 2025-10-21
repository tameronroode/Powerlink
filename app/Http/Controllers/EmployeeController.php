<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;

class EmployeeController extends Controller
{
    // GET /api/employees
    public function index(Request $request)
    {
        $q = Employee::query();

        if ($search = $request->query('q')) {
            $q->where(function ($qq) use ($search) {
                $qq->where('first_name', 'ilike', "%$search%")
                    ->orWhere('last_name', 'ilike', "%$search%")
                    ->orWhere('email', 'ilike', "%$search%");
            });
        }

        return response()->json($q->orderBy('last_name')->limit(100)->get());
    }

    // POST /api/employees
    public function store(Request $request)
    {
        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'last_name' => ['required', 'string', 'max:100'],
            'email' => ['nullable', 'email', 'max:190'],
            'phone_number' => ['nullable', 'string', 'max:50'],
            'role' => ['nullable', 'string', 'max:50'],
            'hire_date' => ['nullable', 'date'],
        ]);

        $emp = Employee::create($data);
        return response()->json($emp, 201);
    }
}

